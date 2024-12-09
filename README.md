# Fordulatszám-szabályozás PID Szabályozóval - FPGA Dokumentáció

## Bevezetés
A fordulatszám-szabályozás alapvető jelentőségű számos ipari és kutatási alkalmazásban, különösen olyan rendszerekben, ahol a precíz motorvezérlés elengedhetetlen. Ez a projekt egy PID szabályozó alapú FPGA implementációt valósít meg, amely a motor fordulatszámának valós idejű szabályozására szolgál. A rendszer három fő modulra oszlik: **Encoder**, **PID szabályozó**, és **PWM generátor**. Továbbá, egy **VIO modul** biztosítja a kívánt fordulatszám dinamikus beállítását.


## Követelmények

### Funkcionális követelmények
1. **Encoder modul**: Valós időben olvassa a motor fordulatszámát, és az adatokat továbbítja a PID szabályozónak.
2. **PID szabályozó modul**: Az enkódertől kapott aktuális fordulatszám alapján kiszámítja a szükséges vezérlő jelet (hibát, valamint a P, I, D komponenst).
3. **PWM jel generálása**: A PID modul által számított vezérlő jel alapján PWM jelet állít elő, amely szabályozza a motor sebességét.

### Nem funkcionális követelmények
- **Teljesítmény**: Az FPGA-n a PID számításnak valós idejű feldolgozásra alkalmasnak kell lennie.
- **Megbízhatóság**: A rendszer stabil működése kritikus.
- **Hatékonyság**: Minimális késleltetés a bemenet (Encoder) és a kimenet (PWM jel) között.

## Specifikációk

1. **Motor interfész**:
   - **Bemenet**: Encoder jelek (A és B csatorna).
   - **Kimenet**: PWM jel (kitöltési tényező szabályozása).
   - PWM frekvencia: Programozható (div_val paraméter alapján).
   
2. **PID paraméterek**:
   - Proporcionális (Kp): 1000.
   - Integrális (Ki): 0.
   - Derivatív (Kd): 5.
   - Ezeket az értékeket az FPGA belső memóriájában tároljuk.

3. **VIO modul**:
   - Referencia fordulatszám beállítása valós időben.

## Architektúra

### 1. Encoder modul
- **Funkció**: A motor tengelyének elfordulását méri a kvadratúra enkóder A és B jelei alapján.
- **Implementáció**: Nem része a projektnek (külső modul).
- **Kimenet**: Az aktuális fordulatszámot reprezentáló érték.

### 2. PID szabályozó modul
- **Állapotgép**:
  - **RDY**: Készenléti állapot.
  - **INIT**: Hibaszámítás inicializálása.
  - **CALC_PID**: A P, I, D komponensek számítása.
  - **SUM_PID**: Összegzés a PID komponensek alapján.
  - **DIVIDE_KG**: Kimeneti jel skálázása.
  - **OVERLOAD**: Túllépés kezelése.
  - **SIGN**: A kimeneti jel irányának meghatározása.
  - **SEND**: A kimeneti jel továbbítása.

#### Állapotdiagram:
```
RDY -> INIT -> CALC_PID -> SUM_PID -> DIVIDE_KG -> OVERLOAD -> SIGN -> SEND -> RDY
```

### 3. PWM generátor modul
- **Állapotgép**:
  - **RDY**: Indítás előtti készenléti állapot.
  - **INIT**: Kitöltési tényező inicializálása.
  - **HIGH**: PWM jel magas szintje.
  - **LOW**: PWM jel alacsony szintje.

#### Állapotdiagram:
```
RDY -> INIT -> HIGH -> LOW -> RDY
```

### 4. Top Modul
- A rendszer modulok közötti összekapcsolásáért felelős.
- Tartalmazza:
  - **VIO modul**: Referencia fordulatszám dinamikus beállítása.
  - **Encoder**: A valós fordulatszám beolvasása.
  - **PID**: Vezérlő jel kiszámítása.
  - **PWM**: Kimeneti PWM jel generálása.


## Tervezési módszerek
1. **Fentről-le tervezés**:
   - A rendszer fő funkcióit először nagy vonalakban terveztük meg (PID, Encoder, PWM), majd részmodulokra bontottuk.
2. **Iteratív fejlesztés**:
   - Az egyes modulokat külön fejlesztettük és teszteltük.
3. **Modularitás**:
   - Minden modul külön VHDL fájlban található, amely könnyen újrahasznosítható és tesztelhető.


## Szimuláció és tesztelés
- **Szimulációs környezet**: A modulokat külön-külön és összekapcsolt rendszerként is teszteltük.
- **VIO modul**:
  - Valós idejű referencia sebesség változtatás.
- **Tesztelő fájlok**:
  - Példák: `custom_clk_tb.vhd`, `pid_tb.vhd`, `mv_signal_tb.vhd`.


## Forráskód áttekintés
1. **Clock Divider**: `custom_clk.vhd`
   - A bemeneti órajelet osztja a PWM generátor számára megfelelő frekvenciára.
   
2. **PID Szabályozó**: `PID.vhd`
   - A hibától (error) függően számítja ki a vezérlő jelet.

3. **PWM Modul**: `pwm_module.vhd`
   - Generálja a PWM kimeneti jelet a PID által számított kitöltési tényezővel.

4. **Hibaszámítás**: `error_m.vhd`
   - Kiszámítja a referencia és az aktuális fordulatszám közötti eltérést.

## Könyvészet
1. PID implementáció VHDL-ben: [GitHub - pid-fpga-vhdl](https://github.com/deepc94/pid-fpga-vhdl)
2. Pololu motorvezérlő: [Pololu VNH5019](https://www.pololu.com/product/1451)

## Mellékletek
- Teljes forráskód.
- Szimulációs fájlok.
- Állapotdiagramok.
