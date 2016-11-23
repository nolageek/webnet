a=`/usr/sbin/exim -bpc`
if test $a -ge 250;
then
echo sending mail about $a
echo | mail -s "mailqueue on `hostname`: $a" -c user@domain.net user2@domain
fi

