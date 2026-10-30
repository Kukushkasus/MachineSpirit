#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Tiny fake MPRIS media player for testing the shell without a real player.
Usage: fake_mpris.py [cover-image-path]   (needs python-dbus-next)"""
import asyncio, sys
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property
from dbus_next import Variant, PropertyAccess

ART = "file://" + (sys.argv[1] if len(sys.argv) > 1 else "/tmp/cover.png")

class Root(ServiceInterface):
    def __init__(self): super().__init__("org.mpris.MediaPlayer2")
    @method()
    def Raise(self): pass
    @method()
    def Quit(self): pass
    @dbus_property(access=PropertyAccess.READ)
    def CanQuit(self) -> "b": return False
    @dbus_property(access=PropertyAccess.READ)
    def CanRaise(self) -> "b": return False
    @dbus_property(access=PropertyAccess.READ)
    def HasTrackList(self) -> "b": return False
    @dbus_property(access=PropertyAccess.READ)
    def Identity(self) -> "s": return "Fake Player"
    @dbus_property(access=PropertyAccess.READ)
    def SupportedUriSchemes(self) -> "as": return []
    @dbus_property(access=PropertyAccess.READ)
    def SupportedMimeTypes(self) -> "as": return []

class Player(ServiceInterface):
    def __init__(self):
        super().__init__("org.mpris.MediaPlayer2.Player")
        self.status = "Playing"; self.pos = 0; self.n = 0
        self.tracks = [("Litany of the Machine", "Choir of Cogs"), ("Rite of Binary", "Forge World Ensemble"), ("Omnissiah Dub", "Servo Skull")]
    def meta(self):
        t, a = self.tracks[self.n % len(self.tracks)]
        return {"mpris:trackid": Variant("o", "/track/%d" % self.n), "mpris:length": Variant("x", 214_000_000),
                "mpris:artUrl": Variant("s", ART), "xesam:title": Variant("s", t), "xesam:artist": Variant("as", [a])}
    @method()
    def Next(self): self.n += 1; self.pos = 0; self.emit_properties_changed({"Metadata": self.meta()})
    @method()
    def Previous(self): self.n -= 1; self.pos = 0; self.emit_properties_changed({"Metadata": self.meta()})
    @method()
    def Pause(self): self.status = "Paused"; self.emit_properties_changed({"PlaybackStatus": self.status})
    @method()
    def PlayPause(self):
        self.status = "Paused" if self.status == "Playing" else "Playing"
        self.emit_properties_changed({"PlaybackStatus": self.status})
    @method()
    def Stop(self): self.Pause()
    @method()
    def Play(self): self.status = "Playing"; self.emit_properties_changed({"PlaybackStatus": self.status})
    @method()
    def Seek(self, offset: "x"): self.pos += offset
    @method()
    def SetPosition(self, track: "o", position: "x"): self.pos = position
    @method()
    def OpenUri(self, uri: "s"): pass
    @dbus_property(access=PropertyAccess.READ)
    def PlaybackStatus(self) -> "s": return self.status
    @dbus_property(access=PropertyAccess.READ)
    def Metadata(self) -> "a{sv}": return self.meta()
    @dbus_property(access=PropertyAccess.READ)
    def Position(self) -> "x": return self.pos
    @dbus_property(access=PropertyAccess.READ)
    def Rate(self) -> "d": return 1.0
    @dbus_property(access=PropertyAccess.READ)
    def MinimumRate(self) -> "d": return 1.0
    @dbus_property(access=PropertyAccess.READ)
    def MaximumRate(self) -> "d": return 1.0
    @dbus_property(access=PropertyAccess.READ)
    def Volume(self) -> "d": return 1.0
    @dbus_property(access=PropertyAccess.READ)
    def CanGoNext(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def CanGoPrevious(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def CanPlay(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def CanPause(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def CanSeek(self) -> "b": return True
    @dbus_property(access=PropertyAccess.READ)
    def CanControl(self) -> "b": return True

async def main():
    bus = await MessageBus().connect()
    bus.export("/org/mpris/MediaPlayer2", Root())
    bus.export("/org/mpris/MediaPlayer2", Player())
    await bus.request_name("org.mpris.MediaPlayer2.fakeplayer")
    await asyncio.get_event_loop().create_future()

asyncio.run(main())
