import math

import google.cloud.firestore
from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn

initialize_app()

ACTIVITY_THRESHOLD = 40


def motion_activity(text):
    previous = None
    total = 0.0
    count = 0
    for line in text.split("\n"):
        parts = line.split(",")
        if len(parts) < 4:
            continue
        try:
            x = float(parts[1])
            y = float(parts[2])
            z = float(parts[3])
        except ValueError:
            continue
        magnitude = math.sqrt(x * x + y * y + z * z)
        if previous is not None:
            total += abs(magnitude - previous)
            count += 1
        previous = magnitude
    return total / count if count > 0 else 0.0


def heart_rate(text):
    total = 0.0
    count = 0
    for line in text.split("\n"):
        parts = line.split(",")
        if len(parts) < 3:
            continue
        try:
            bpm = float(parts[1])
            status = int(parts[2])
        except ValueError:
            continue
        if status != 1 or bpm <= 0:
            continue
        total += bpm
        count += 1
    return total / count if count > 0 else None


@google.cloud.firestore.transactional
def mark_wake(transaction, session, reason):
    current = session.get(transaction=transaction)
    if not current.exists:
        return False
    data = current.to_dict() or {}
    if data.get("wakeNow") is True:
        return True
    if (data.get("alarm") or {}).get("smart") is not True:
        return False
    transaction.update(
        session,
        {
            "wakeNow": True,
            "wakeDecidedAt": firestore.SERVER_TIMESTAMP,
            "wakeReason": reason,
        },
    )
    return True


@https_fn.on_call(region="me-central1")
def check_epoch(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "sign in first")
    data = req.data or {}
    session_id = data.get("sessionId")
    index = data.get("index")
    if not isinstance(session_id, str) or session_id == "" or "/" in session_id:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "bad sessionId")
    if not isinstance(index, int) or index < 0:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "bad index")

    db = firestore.client()
    session = db.collection("users").document(req.auth.uid).collection("sleepSessions").document(session_id)
    epochs = session.collection("epochs")

    snapshot = epochs.document(str(index).zfill(4)).get()
    if not snapshot.exists:
        return {"wake": False, "activity": None, "hr": None}
    epoch = snapshot.to_dict() or {}

    activity = motion_activity(epoch.get("motion") or "")
    hr = heart_rate(epoch.get("heart") or "")
    snapshot.reference.update({"activity": activity, "hr": hr})

    if activity < ACTIVITY_THRESHOLD or index == 0:
        return {"wake": False, "activity": activity, "hr": hr}

    previous = epochs.document(str(index - 1).zfill(4)).get()
    if not previous.exists:
        return {"wake": False, "activity": activity, "hr": hr}
    previous_data = previous.to_dict() or {}
    previous_activity = previous_data.get("activity")
    if previous_activity is None:
        previous_activity = motion_activity(previous_data.get("motion") or "")
    if previous_activity < ACTIVITY_THRESHOLD:
        return {"wake": False, "activity": activity, "hr": hr}

    reason = {
        "index": index,
        "activity": activity,
        "previousActivity": previous_activity,
        "hr": hr,
    }
    wake = mark_wake(db.transaction(), session, reason)
    return {"wake": wake, "activity": activity, "hr": hr}