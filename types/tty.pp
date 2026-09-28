# A tty name, as listed in `/etc/securetty`
type Useradd::Tty = Pattern[/\A[A-Za-z0-9_.:\/-]+\z/]
