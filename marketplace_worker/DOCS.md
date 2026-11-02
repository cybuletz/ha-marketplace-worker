# Marketplace Fleet Worker

Transformă serverul Home Assistant într-un nod de scanare pentru flota Marketplace.

## Ce face și ce nu face

- Descarcă pagini publice de magazine (eMAG și alții) și trimite rezultatele prin HTTPS către Master Hub.
- **Doar conexiuni de ieșire.** Nu deschide niciun port, nu are nevoie de port forwarding și nu folosește rețeaua host-ului.
- **Nu are acces la Home Assistant.** Add-on-ul nu cere acces la API-ul HA, la configurație sau la dispozitive.
- Scriptul worker-ului se descarcă de pe Master la prima pornire și se actualizează singur când apare o versiune nouă. O versiune nouă care cade de mai multe ori la pornire este înlocuită automat cu ultima versiune bună.

## Cerințe

- Home Assistant OS sau Home Assistant Supervised (adică trebuie să existe meniul **Settings → Add-ons**).
  Pe Home Assistant Container sau Core nu există add-on-uri; vezi mai jos varianta Docker.
- Procesor x86-64 (amd64) sau ARM pe 64 de biți (aarch64, de exemplu Raspberry Pi 4/5 cu OS pe 64 de biți).
- Aproximativ 2,5 GB spațiu liber pentru imagine și 0,5–1,2 GB RAM când rulează browserul.

## Instalare

1. **Settings → Add-ons → Add-on Store**, apoi meniul cu trei puncte (dreapta sus) → **Repositories**.
2. Adaugă `https://github.com/cybuletz/ha-marketplace-worker` și apasă **Add**, apoi **Close**.
3. Caută **Marketplace Fleet Worker** în listă și apasă **Install**. Prima descărcare durează câteva minute (~1,5 GB).
4. În tab-ul **Configuration** completează:
   - **worker_token**: tokenul primit de la administrator;
   - **worker_name**: un nume ușor de recunoscut, de exemplu `Aurel HA`.
   Restul câmpurilor pot rămâne cu valorile implicite.
5. Apasă **Save**, apoi în tab-ul **Info** pornește **Start on boot** și **Auto update**, și apasă **Start**.
6. În tab-ul **Log** ar trebui să apară `worker.py downloaded` și apoi mesajele worker-ului care se conectează la Master.

## Opțiuni

| Opțiune | Implicit | Ce face |
| --- | --- | --- |
| `master_url` | `https://worker.cybu.net` | Adresa serverului central. |
| `worker_token` | (gol) | Tokenul secret. Fără el add-on-ul așteaptă și nu face nimic. |
| `worker_id` | (gol) | ID-ul din dashboard. Gol înseamnă că se generează o dată, de exemplu `ha-3f9a1c2b`, și rămâne același. |
| `worker_name` | (gol) | Nume afișat. Gol înseamnă același ca ID-ul. |
| `request_delay_min` / `request_delay_max` | 2,5 / 4,5 | Pauza aleatoare dintre pagini, în secunde. Mai mare înseamnă mai puțin trafic. |

## Oprire și dezinstalare

Apasă **Stop** ca să oprești temporar worker-ul sau **Uninstall** ca să-l elimini complet. Nu rămâne nimic instalat în Home Assistant.

## Fără Supervisor (Home Assistant Container / Core)

Aceeași imagine rulează și cu Docker simplu:

```bash
mkdir -p ~/marketplace-worker && cd ~/marketplace-worker
cat > options.json <<'EOF'
{"master_url": "https://worker.cybu.net", "worker_token": "TOKENUL_TAU", "worker_id": "", "worker_name": "Aurel", "request_delay_min": 2.5, "request_delay_max": 4.5}
EOF
docker run -d --name marketplace-worker --restart unless-stopped --shm-size 1g \
  -v "$PWD:/data" ghcr.io/cybuletz/ha-marketplace-worker-amd64:latest
```

Pe ARM folosește `ha-marketplace-worker-aarch64`.
