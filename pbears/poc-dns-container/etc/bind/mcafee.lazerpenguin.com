;
; Zone file for tunnelbear.server
;
; The full zone file
;
$TTL 3D
@       IN      SOA     ns.mcafee.lazerpenguin.com. dns-admin.mcafee.lazerpenguin.com. (
                        1       ; serial, todays date + todays serial #
                        900     ; refresh, seconds
                        900     ; retry, seconds
                        1800    ; expire, seconds
                        60 )    ; minimum, seconds
;
                NS      ns              ; Inet Address of name server

@              A       172.17.1.2
ns             A       127.0.0.1
