"""CPU detection by structural anchors; explicit selection still validates widths."""
from .base import ViewerError
from .legacy import LegacyProfile
from .v1 import V1Profile
from .v2 import V2Profile

PROFILES = {p.cpu:p for p in (LegacyProfile,V1Profile,V2Profile)}

def select_profile(paths, requested="auto"):
    if requested != "auto":
        return PROFILES[requested]()
    matches = [cls() for cls in PROFILES.values() if cls().discover(paths)]
    if len(matches) != 1:
        raise ViewerError("CPU auto-detection ambiguous/unsupported. Use --cpu legacy|v1|v2; "
                          "required hierarchy and widths will still be checked.")
    return matches[0]
