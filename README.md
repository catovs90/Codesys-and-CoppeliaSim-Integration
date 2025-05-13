# PLS Simuleringsverktøy – Modbus og Lua-skript for CoppeliaSim

Dette repositoriet inneholder nyttige verktøy og script utviklet som del av et hovedprosjekt ved Fagskolen Vestland. Målet er å gjøre det enklere for studenter og undervisere å koble sammen CoDeSys og CoppeliaSim via ModbusTCP, samt å tilby ferdige Lua-script som kan brukes eller tilpasses i egne CoppeliaSim-scener.

## Innhold

### 🔧 `pyInstallerModbus`
- Laster ned nødvendige moduler automatisk (f.eks. `pymodbus`, `requests`, `pywin32`, osv.)

**Formål:** Redusere friksjon i oppstartsfasen ved å automatisere installasjon og oppsett for kommunikasjon mellom CoDeSys og CoppeliaSim.

### 📦 Lua-skript for CoppeliaSim
Et utvalg generelle og gjenbrukbare Lua-script utviklet som modulære komponenter:
- Digitale og analoge sensorer
- Objektbasert deteksjon
- Posisjonsstyrte ledd (lineære og roterende)
- Transportbanekontroll
- Objekt-spawning med auto-destruksjon under definert høyde

Disse er laget med tanke på enkel integrering og tilpasning i egne scener.

---

## 📥 Kom i gang

1. **Last ned og kjør `pyInstallerModbus.py`**
   - Scriptet sjekker og installerer alt som trengs for å bruke Python sammen med CoDeSys og CoppeliaSim.
   - Følg Youtube-film for korrekt installasjon av Python
   - Kjør scriptet i IDLE som fulgte installasjonen
2. **Importer Lua-skript i din CoppeliaSim-scene**
   - Lua-skriptene kan kopieres direkte inn i nye objekter eller brukes som utgangspunkt for egne modifikasjoner.

---

## 📚 Dokumentasjon og veiledning

Dokumentasjonen finnes i form av vårt hovedprosjekt.

---

## 🧪 Testet på

- Windows 10/11 med ulike PC-produsenter
- CoppeliaSim 4.7+
- Python 3.10+
- CoDeSys med ModbusTCP-server aktivert

---

## 📄 Lisens

Dette prosjektet er delt for utdanningsformål og fritt tilgjengelig for ikke-kommersiell bruk. Se LICENSE-filen for mer informasjon.

---

## 🙋 Bidrag

For spørsmål eller forbedringsforslag, ta kontakt via repoets issues-seksjon eller send en pull request.

