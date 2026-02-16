import re


_CYRILLIC_RE = re.compile(r"[А-Яа-яЁё]")
_MOJIBAKE_MARKERS = ("Ð", "Ñ", "Ã", "Â")
_BROKEN_PAIR_RE = re.compile(r"(?:Р.|С.){3,}")


def _try_redecode(value: str, source_encoding: str) -> str | None:
    try:
        return value.encode(source_encoding).decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return None


def _score_text(value: str) -> float:
    if not value:
        return -1000.0

    length = len(value)
    cyrillic_count = len(_CYRILLIC_RE.findall(value))
    marker_penalty = sum(value.count(marker) for marker in _MOJIBAKE_MARKERS) * 2.0
    broken_penalty = 8.0 if _BROKEN_PAIR_RE.search(value) else 0.0
    replacement_penalty = value.count("�") * 4.0

    return (
        (cyrillic_count / length) * 100.0
        - marker_penalty
        - broken_penalty
        - replacement_penalty
    )


def normalize_possible_mojibake(value: str) -> str:
    if not isinstance(value, str) or not value:
        return value

    best = value
    best_score = _score_text(value)
    candidates = {value}

    for encoding in ("latin1", "cp1251"):
        decoded_once = _try_redecode(value, encoding)
        if decoded_once:
            candidates.add(decoded_once)
            decoded_twice = _try_redecode(decoded_once, encoding)
            if decoded_twice:
                candidates.add(decoded_twice)

    for candidate in candidates:
        candidate_score = _score_text(candidate)
        if candidate_score > best_score:
            best = candidate
            best_score = candidate_score

    return best
