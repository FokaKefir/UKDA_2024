# Fordulatszám szabályozás PID megvalósításával

**Hallgató**: Babos Dávid

**Szak**: Számítástechnika, IV. év

**Tantárgy**: Újrakonfigurálható digitális áramkörök

Projekt véglegesítésének időpontja: TODO

# Projekt célja

A fordulatszám-szabályozás alapvető jelentőségű számos ipari és kutatási alkalmazásban, különösen olyan rendszerekben, ahol a precíz motorvezérlés elengedhetetlen. Ez a projekt egy PID szabályozó alapú FPGA implementációt valósít meg, amely a motor fordulatszámának valós idejű szabályozására szolgál. A rendszer fő moduljai: **PID szabályozó**, és **PWM generátor, elsőrendű rendszer, másodrendűrendű rendszer**. Továbbá, egy **VIO modul** biztosítja a kívánt fordulatszám dinamikus beállítását.

# Követelmények

## **Funkcionális követelmények**

1. **PID szabályozó modul**: Az enkódertől kapott aktuális fordulatszám alapján kiszámítja a szükséges vezérlő jelet (hibát, valamint a P, I, D komponenst).
2. **PWM jel generálása**: A PID modul által számított vezérlő jel alapján PWM jelet állít elő, amely szabályozza a motor sebességét.
3. **Elsőrendű rendszer:** a PID modul által számított értékre fog reagálni, parametrizálható módon fog úgy viselkedni, mint egy elsőrendű rendszer.
4. **Másodrendű rendszer:** a PID modul által számított értékre fog reagálni, parametrizálható módon fog úgy viselkedni, mint egy másodrendű rendszer.

## **Nem funkcionális követelmények**

- **Teljesítmény**: Az FPGA-n a PID számításnak valós idejű feldolgozásra alkalmasnak kell lennie.
- **Megbízhatóság**: A rendszer stabil működése kritikus.
- **Hatékonyság**: Minimális késleltetés a bemenet (Encoder) és a kimenet (PWM jel) között.

# Tervezés

1. **Fentről-le tervezés**: A rendszer fő funkcióit először nagy vonalakban lett megtervezve (PID, Encoder, PWM), majd részfeladatokra lettek bontva.
2. **Modularitás**: Minden modul külön VHDL fájlban található, amely könnyen újrahasznosítható és tesztelhető.

**TODO: tömbvázlat**

# Architektúra

## Órajel-osztó

A bemeneti órajelet (`src_clk`) egy alacsonyabb frekvenciájú órajellé alakítja át a `div_val` bemeneti érték alapján.

**VHDL**:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.ALL;

entity custom_clk is
    Port ( src_clk : in STD_LOGIC;
           reset : in std_logic;
           div_val : in STD_LOGIC_VECTOR (9 downto 0);
           q_clk : out STD_LOGIC);
end custom_clk;

architecture Behavioral of custom_clk is

begin

process(src_clk,reset)

variable x: integer range 1023 downto 0 := 0;
variable q: std_logic := '0';

begin 
if reset ='1' then
    x:=0;
    q:='0';
elsif src_clk'event and  src_clk='1' then
    if x<div_val then
        x:=x+1;
        q:=q;
    else
        x:=1;
        q:=not(q);
    end if;
end if;
q_clk<=q;
end process;

end Behavioral;
```

## Mintevételező modul

A modul egy mintavételező jelet generál, amely a bemeneti órajel frekvenciáján alapul, de az **`period`** paraméter által meghatározott intervallumonként egy **`'1'`** aktív impulzust állít elő.

**VHDL**:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.ALL;

entity MV_signal is       
    port( q_clk : in std_logic;
          reset : in std_logic;
          period : in std_logic_vector(15 downto 0);
          out_signal : out std_logic
    );
end MV_signal;

architecture Behavioral of MV_signal is

begin

process(q_clk,reset)

variable x: integer range 65535 downto 0 := 0;
variable out_sig: std_logic :='0';

begin
if reset ='1' then
    x:=1;
    out_sig:='0';
elsif q_clk'event and  q_clk='1' then
    if out_sig='0' then 
        if x < period then
            x:=x+1;
        else
            out_sig := '1';
        end if;
    else
        out_sig := '0';
        x := 1;
    end if;
      
end if;

out_signal<= out_sig;

end process;
end Behavioral;
```

## Error modul

Ez a modul egy egyszerű aritmetikai műveletet végez: kiszámítja az **elvárt érték** és az **aktuális érték** közötti eltérést (**hibaérték**), és az eredményt 16 bites előjeles formátumban adja vissza.

**PID szabályozó modulban**: A referencia és aktuális fordulatszám közötti eltérés kiszámítása.

**VHDL**:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity error_m is
    Port ( exp_turn : in signed (14 downto 0);
           act_turn : in signed (14 downto 0);
           error_val : out signed (15 downto 0));
end error_m;

architecture Behavioral of error_m is
begin
    error_val <= resize(exp_turn, 16) - resize(act_turn, 16);
end Behavioral;
```

## PID szabályzó modul

A megadott PID szabályozó (proporcionális-integrál-derivált) implementáció VHDL-ben három fő paraméterrel dolgozik:**Kp**, **Ki**, **Kd**. Ezek az egyes komponensek hozzájárulásait szabályozzák a szabályozó kimenetéhez, és meghatározzák a rendszer dinamikáját és stabilitását.

$$
\text{PID}_{\text{output}} = K_p \cdot e[k] + K_i \cdot \sum_{j=0}^k e[j] + K_d \cdot (e[k] - e[k-1])
$$

- **e[k]**: a hibajel (error)
- **Kp**: proporcionális erősítés
- **Ki**: integrálási tényező
- **Kd**: derivált tényező

### **Kp: Proporcionális tényező**

- **Hatása:**
    - A proporcionális tényező a hibajel **e[k]** nagyságával arányos módon hat a kimenetre.
    - **Nagyobb Kp:** Gyorsabb válaszidő, de hajlamosabb túllövésre (overshoot). A nagy Kp esetén a rendszer instabillá válhat, különösen, ha a Kd és Ki nincs megfelelően beállítva.
    - **Kisebb Kp:** Stabilabb rendszer, de lassabb válasz, és lehet, hogy a rendszer nem tudja elérni a kívánt értéket (maradék hiba - steady-state error).
- **Jelentősége:**
    - Elsősorban a beállási idő (**Ts**) csökkentéséhez használjuk, de nem képes önmagában teljesen megszüntetni a maradék hibát.

### **Ki: Integrálási tényező**

- **Hatása:**
    - Az integráló komponens az összesített hibajel ( $\sum e[j]$ ) alapján hat a kimenetre, azaz a hibajel időbeli átlagát is figyelembe veszi.
    - **Nagyobb Ki:** Gyorsabban megszünteti a maradék hibát, de oszcillációkat okozhat, és növelheti a túllövést.
    - **Kisebb Ki:** Lassabban csökkenti a maradék hibát, de stabilabbá teheti a rendszert.
- **Jelentősége:**
    - Az integráló tag kiküszöböli a maradék hibát (**steady-state error**), különösen, ha a rendszer hosszabb ideig állandó hibajelnek van kitéve.

### **Kd: Derivált tényező**

- **Hatása:**
    - A derivált komponens a hibajel változási sebessége ($\Delta e[k]$) alapján hat a kimenetre, így előrejelző mechanizmusként működik.
    - **Nagyobb Kd:** Csökkenti a túllövést és csillapítja az oszcillációkat, de ha túl nagy, zajérzékennyé teheti a rendszert.
    - **Kisebb Kd:** Kevésbé befolyásolja az oszcillációkat, de a rendszer válaszideje lassabb lehet.
- **Jelentősége:**
    - A deriváló tag csillapítja a rendszer válaszát, megakadályozva a túlzott túllövést és az oszcillációt.


**Állapotgép**:

- **RDY**: Készenléti állapot.
- **INIT**: Hibaszámítás inicializálása.
- **CALC_PID**: A P, I, D komponensek számítása.
- **SUM_PID**: Összegzés a PID komponensek alapján.
- **DIVIDE_KG**: Kimeneti jel skálázása.
- **OVERLOAD**: Túllépés kezelése.
- **SIGN**: A kimeneti jel irányának meghatározása.
- **SEND**: A kimeneti jel továbbítása.

**Állapotdiagram**:

```
RDY -> INIT -> CALC_PID -> SUM_PID -> DIVIDE_KG -> OVERLOAD -> SIGN -> SEND -> RDY
```

**VHDL**:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity PID is
    Port ( 
        q_clk : in STD_LOGIC;
        src_ce : in std_logic;
        src_reset : in std_logic;
        start : in std_logic;
        error : in STD_LOGIC_VECTOR (15 downto 0);   
        output : out STD_LOGIC_VECTOR (15 downto 0);
        dir : out std_logic_vector (1 downto 0)
    );
end PID;

architecture Behavioral of PID is

type statetypes is (RDY, INIT, CALC_PID, SUM_PID, DIVIDE_KG, OVERLOAD, SIGN, SEND);
signal actual_state, next_state : statetypes;

-- PID parameters
signal Kp : integer := 1000;
signal Kd : integer := 5;
signal Ki : integer := 0;

-- signals for calculations
signal output_signed : signed(16 downto 0) := (others => '0');
signal inter : signed (31 downto 0) := (others => '0');
signal error_signed : signed(15 downto 0) := (others => '0');
signal p, i, d : signed(31 downto 0) := (others => '0');
signal output_carrier : STD_LOGIC_VECTOR (15 downto 0);

begin

state_r : process(q_clk, src_reset)
begin
    if src_reset = '1' then
        actual_state <= RDY;
    elsif (q_clk'event and q_clk = '1') then
        actual_state <= next_state;
    end if;
end process state_r;

next_state_logic : process(actual_state, start)
begin
    case actual_state is
        when RDY =>
            if start = '1' then
                next_state <= INIT;
            else
                next_state <= RDY;
            end if;
        when INIT => 
            next_state <= CALC_PID;
        when CALC_PID =>
            next_state <= SUM_PID;
        when SUM_PID =>
            next_state <= DIVIDE_KG;
        when DIVIDE_KG =>
            next_state <= OVERLOAD;
        when OVERLOAD =>
            next_state <= SIGN;
        when SIGN => 
            next_state <= SEND;
        when SEND =>
            next_state <= RDY;
    end case;
end process next_state_logic;

process(actual_state)
    variable error_old : signed(15 downto 0) := (others => '0');
begin

    case actual_state is
        when RDY =>
            output_signed <= (others => '0');
            error_signed <= (others => '0');
            inter <= (others => '0');
            p <= (others => '0');
            i <= (others => '0');
            d <= (others => '0');
        when INIT => 
            error_signed <= signed(error);
        when CALC_PID =>
            p <= Kp * error_signed;
            i <= Ki * (error_signed + error_old);
            d <= Kd * (error_signed - error_old);
        when SUM_PID =>
            inter <= p + i + d;
        when DIVIDE_KG =>
            output_signed <= resize(inter / 2048, 17);
        when OVERLOAD =>
            if output_signed > to_signed(32767, 17) then
                output_signed <= to_signed(32767, 17);
            elsif output_signed < to_signed(-32768, 17) then 
                output_signed <= to_signed(-32768, 17);
            end if;
        when SIGN => 
            if output_signed = 0 then
                output_carrier <= (others => '0');
                dir <= "00";
            elsif output_signed < 0 then
                output_carrier <= std_logic_vector(-output_signed(15 downto 0));
                dir <= "10";
            else
                output_carrier <= std_logic_vector(output_signed(15 downto 0));
                dir <= "01";
            end if;
            
        when SEND =>
            output <= output_carrier;
            error_old := error_signed;   
    end case;
end process;

end Behavioral;
```

## PWM generátor modul

**Állapotgép**:

- **RDY**: Indítás előtti készenléti állapot.
- **INIT**: Kitöltési tényező inicializálása.
- **HIGH**: PWM jel magas szintje.
- **LOW**: PWM jel alacsony szintje.

**Állapotdiagram:**

```
RDY -> INIT -> HIGH -> LOW -> RDY
```

**VHDL**:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity pwm_ultra is
    Port ( 	src_clk : in  STD_LOGIC;
            src_ce : in  STD_LOGIC;
            reset : in  STD_LOGIC;
            h : in  STD_LOGIC_VECTOR (15 downto 0);
         min_val : in STD_LOGIC_VECTOR (15 downto 0);
         max_val : in STD_LOGIC_VECTOR (15 downto 0);
            pwm_out : out  STD_LOGIC);
end pwm_ultra;

architecture Behavioral of pwm_ultra is

type casee is(RDY,INIT,HIGH,LOW);
signal actual_case : casee;
signal next_case : casee;
signal pwm_sig, pwm_next_sig : STD_LOGIC;
signal counter, counter_next : STD_LOGIC_VECTOR(15 downto 0);

begin

State_R:process(src_clk,reset)
begin

    if reset = '1' then
         actual_case <= RDY;
         counter <= (others => '0');
         pwm_sig <= '0';
   elsif (src_clk'event and src_clk='1') then
         actual_case <= next_case;
         counter <= counter_next;
         pwm_sig <= pwm_next_sig;
   end if;

end process State_R;

next_case_log:process(actual_case, counter, h)
begin

case(actual_case) is
   when RDY =>
      next_case<=INIT;
      
   when INIT =>
      if counter < min_val
         then
            next_case<=INIT;
         else
            next_case<=HIGH;
      end if;

   when HIGH =>
      if counter< (h+min_val)  	
         then	
            next_case<=HIGH;
         else
            next_case<=LOW;
      end if;
      
   when LOW =>
      if counter<max_val  
         then
            next_case<=LOW;
         else
            next_case<=RDY;
      end if;
   end case;
end process next_case_log;

WITH actual_case SELECT 
counter_next<=	(others => '0')	WHEN RDY,
            counter + 1     WHEN others; 
            
            
WITH actual_case SELECT
pwm_next_sig<= 	'0' WHEN RDY,
            '1' WHEN INIT,
            '1' WHEN HIGH,
            '0' WHEN LOW;

pwm_out<=pwm_next_sig;

end Behavioral;

```

## Elsőrendű rendszer

A modul egy **elsőfokú rendszer** (first-order system) diszkrét implementációját tartalmazza. A viselkedését az **A** és **B** paraméterek határozzák meg, amelyeket fixpontos **Q15** formátumban adtak meg, azaz **32768** értékre skálázott számokkal számol a rendszer.

$$
\text{speed}_{\text{next}} = \frac{A}{32768} \cdot \text{speed}_{\text{current}} + \frac{B}{32768} \cdot \text{input\_val}
$$

Az **A** paraméter a rendszer dinamikáját határozza meg azáltal, hogy befolyásolja az állapot változásának sebességét, azaz a rendszer időállandóját.

- **Nagyobb**: A visszacsatolás erősebb, a rendszer lassabban áll be (hosszabb időállandó). Nagy **A**-val a rendszer "lustább", azaz lassan reagál a bemenetekre.
- **Kisebb**: Gyorsabb beállás, kisebb időállandó. Ha **A** túl kicsi, a rendszer instabillá válhat.

A **B** paraméter a rendszer bemeneti jele **input_val** által generált gyorsulást határozza meg. Ez az erősítési tényező hatással van arra, hogy a bemenet **sys_in** milyen mértékben befolyásolja az állapot **speed** változását.

- **Nagyobb**: A bemeneti jel **sys_in** erősebben befolyásolja a rendszert, nagyobb az erősítés.
- **Kisebb**: A rendszer kevésbé érzékeny a bemenetre.

**VHDL**:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity first_order_system is
    generic(
        -- A and B as Q15 parameters.
        A : integer := 30000;  -- Example pole factor
        B : integer := 5000    -- Example gain factor
    );
    Port (
        q_clk    : in  std_logic;
        reset    : in  std_logic;
        enable   : in  std_logic;
        sys_in  : in  signed(15 downto 0);  
        dir      : in  std_logic_vector(1 downto 0);
        sys_out  : out signed(14 downto 0) 
    );
end first_order_system;

architecture Behavioral of first_order_system is

    -- 15-bit signed range: -16384 to +16383
    signal speed     : signed(14 downto 0) := (others => '0');
    signal input_val : signed(15 downto 0) := (others => '0');
   

begin

    process(q_clk, reset)
         variable temp : integer;
    begin
        if reset = '1' then
            speed <= (others => '0');
        elsif rising_edge(q_clk) then
            if enable = '1' then
                -- Determine input_val based on direction
                case dir is
                    when "01" => input_val <= sys_in;               -- Forward torque
                    when "10" => input_val <= -sys_in;              -- Reverse torque
                    when others => input_val <= (others => '0');    -- No torque
                end case;

                -- speed_next = (A/32768)*speed + (B/32768)*input_val
                temp := (to_integer(speed)*A)/32768 + (to_integer(input_val)*B)/32768;

                -- Saturate to 15-bit range: -16384 to +16383
                if temp > 16383 then
                    speed <= to_signed(16383, 15);
                elsif temp < -16384 then
                    speed <= to_signed(-16384, 15);
                else
                    speed <= to_signed(temp, 15);
                end if;
            end if;
        end if;
    end process;

    sys_out <= speed;

end Behavioral;
```

## Másodrendű rendszer

A **másodfokú rendszer** modulját az **A1**, **A2**, **B** paraméterekkel modellezi a viselkedését. Ezek a paraméterek a rendszer dinamizmusát és stabilitását határozzák meg. A másodfokú rendszerek általában jobban modellezik az olyan rendszereket, amelyek tehetetlenséggel, csillapítással vagy oszcillációval rendelkeznek.

$$
y[k+1] = \frac{A_1}{32768} \cdot y[k] + \frac{A_2}{32768} \cdot y[k-1] + \frac{B}{32768} \cdot u[k]
$$

**A1 - Első állapot visszacsatolási tényező**: ez a tényező azt határozza meg, hogy az aktuális kimenet (**y[k]**), milyen mértékben befolyásolja a következő állapotot (**y[k+1]**)

- **Nagyobb**: A rendszer stabilabbá válik, de lassabban áll be. Az **A1** nagy értéke kevésbé engedi, hogy a bemenet domináljon.
- **Kisebb**: Az aktuális állapot kevésbé hat a következő állapotra, ami gyorsabb változást eredményez.

**A2 - Második állapot visszacsatolási tényező**:  Az **A2** szabályozza, hogy az előző időpillanat állapota (**y[k - 1]**) milyen mértékben járul hozzá a következő állapothoz.

- **Pozitív**: Növeli a rendszer oszcillációját. Ha túl nagy, akkor a rendszer oszcilálhat vagy instabillá válhat.
- **Negatív**: Csillapítja a rendszert, de túl nagy abszolút értékű **A2** túllövést okozhat.

**B - Bemeneti erősítés (gain)**: A **B** paraméter szabályozza, hogy a bemenet (**y[k]**) milyen mértékben folyásolja be az aktuális állapotot.

- **Nagyobb**: Az input dominálja a rendszer viselkedését, ami gyorsabb válaszidőt eredményez, de érzékenyebbé teheti a rendszert.
- **Kisebb**: A rendszer kevésbé érzékeny a bemenetre, stabilabb, de lassabban reagál.

Az **A1** és **A2** kombinációja határozza meg a rendszer stabilitását. A rendszer stabil, ha a karakterisztikus polinom gyökei egységsugaron belül vannak a komplex síkon. Ez gyakorlatilag azt jelenti, hogy  $|A_1| + |A_2| < 1$ , normalizált értékekkel.

**VHDL:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity second_order_system is
    generic(
        A1 : integer := 20000;   -- Approx 0.61 in Q15 scaling (20000/32768 ~ 0.61)
        A2 : integer := -10000;  -- Approx -0.30 in Q15 scaling (-10000/32768 ~ -0.30)
        B  : integer := 5000     -- Approx 0.15 in Q15 scaling (5000/32768 ~ 0.15)
    );
    Port (
        q_clk    : in  std_logic;
        reset    : in  std_logic;
        enable   : in  std_logic;
        sys_in  : in  signed(15 downto 0);
        dir      : in  std_logic_vector(1 downto 0);
        sys_out  : out signed(14 downto 0)
    );
end second_order_system;

architecture Behavioral of second_order_system is

    -- 15-bit signed range: -16384 to +16383
    signal y_k     : signed(14 downto 0) := (others => '0');  -- y(k)
    signal y_km1   : signed(14 downto 0) := (others => '0');  -- y(k-1)
    signal input_val : signed(15 downto 0) := (others => '0');
    
    
begin

    process(q_clk, reset)
        variable temp : integer;
    begin
        if reset = '1' then
            -- Initialize both states to zero
            y_k   <= (others => '0');
            y_km1 <= (others => '0');
        elsif rising_edge(q_clk) then
            if enable = '1' then
                -- Determine input based on direction
                case dir is
                    when "01" => input_val <= sys_in;               -- forward
                    when "10" => input_val <= -sys_in;              -- reverse
                    when others => input_val <= (others => '0');    -- no input
                end case;
                
                -- y(k+1) = A1*y(k) + A2*y(k-1) + B*u(k)
                temp := (to_integer(y_k)*A1)/32768 +
                        (to_integer(y_km1)*A2)/32768 +
                        (to_integer(input_val)*B)/32768;

                -- Saturation to 15-bit range: [-16384, 16383]
                if temp > 16383 then
                    y_km1 <= y_k;  -- update old states
                    y_k   <= to_signed(16383, 15);
                elsif temp < -16384 then
                    y_km1 <= y_k;
                    y_k   <= to_signed(-16384, 15);
                else
                    y_km1 <= y_k;
                    y_k   <= to_signed(temp, 15);
                end if;
            end if;
        end if;
    end process;

    sys_out <= y_k;

end Behavioral;
```

# Szimuláció és tesztelés

## Szimuláció

### Elsőrendű rendszer

A rendszert teszteljük egységugrásra, hogy milyen választ ad és megfigyeljük, hogy az **A** és **B** paraméterek, hogy folyásolják be a rendszert:

- Amennyiben **A=30000** és **B=2000** a rendszerünk lassan de stabilan áll be a végállapotba (1100ns).
    
    ![image.png](image.png)
    
- Amennyiben **A=20000** és **B=8000** a rendszer hamar beáll a végállapotba, viszont nagyon érzékeny lesz a bemenetre (350ns)
    
    ![image.png](image%201.png)
    

**VHDL**:

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity first_order_system_tb is
end first_order_system_tb;

architecture Behavioral of first_order_system_tb is

    component first_order_system is
        generic(
            A : integer := 30000;
            B : integer := 5000
        );
        Port (
            q_clk    : in  std_logic;
            reset    : in  std_logic;
            enable   : in  std_logic;
            sys_in  : in  signed(15 downto 0);    
            dir      : in  std_logic_vector(1 downto 0);
            sys_out  : out signed(14 downto 0)     
        );
    end component;

    signal q_clk   : std_logic := '0';
    signal reset   : std_logic := '1';
    signal enable  : std_logic := '1';
    signal sys_in : signed(15 downto 0) := (others => '0');
    signal dir     : std_logic_vector(1 downto 0) := "00";
    signal sys_out : signed(14 downto 0);  

    constant CLK_PERIOD : time := 20 ns;

begin

    UUT: first_order_system
        generic map(
            A => 30000,  
            B => 2000
        )
        port map(
            q_clk   => q_clk,
            reset   => reset,
            enable  => enable,
            sys_in => sys_in,
            dir     => dir,
            sys_out => sys_out
        );

    -- Clock generation
    clk_process: process
    begin
        q_clk <= '0';
        wait for CLK_PERIOD/2;
        q_clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initially hold reset for 100 ns
        wait for 100 ns; 
        reset <= '0'; 

        -- Wait a bit before applying the step input
        wait for 200 ns;

        -- Apply a step input: set sys_in to a value and direction forward
        sys_in <= to_signed(1000,16);  -- 16-bit signed magnitude
        dir <= "01";  -- forward direction
        
        -- Let the simulation run and observe output
        wait for 6000 ns;

        -- Finish simulation
        wait;
    end process;

end Behavioral;
```

### Másodrendű rendszer

A rendszert teszteljük egységugrásra, hogy milyen választ ad és megfigyeljük, hogy az **A1, A2** és **B** paraméterek, hogy folyásolják be a rendszert:

- Amennyiben **A1=25000**, **A2=-10000** és **B=5000** a rendszernek rövid a beállási ideje és az oszcilláció minimális.
    
    ![image.png](image%202.png)
    
- Amennyiben **A1=20000**, **A2=10000** és **B=6000** a rendszernek lassú a válaszideje és növekszik a túllövés, túlzott oszcilláció
    
    ![image.png](image%203.png)
    

**VHDL:**

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity second_order_system_tb is
end second_order_system_tb;

architecture Behavioral of second_order_system_tb is

    component second_order_system is
        generic(
            A1 : integer := 20000;
            A2 : integer := -10000;
            B  : integer := 5000
        );
        Port (
            q_clk    : in  std_logic;
            reset    : in  std_logic;
            enable   : in  std_logic;
            sys_in  : in  signed(15 downto 0); 
            dir      : in  std_logic_vector(1 downto 0);
            sys_out  : out signed(14 downto 0)  
        );
    end component;

    signal q_clk   : std_logic := '0';
    signal reset   : std_logic := '1';
    signal enable  : std_logic := '1';
    signal sys_in : signed(15 downto 0) := (others => '0');
    signal dir     : std_logic_vector(1 downto 0) := "00";
    signal sys_out : signed(14 downto 0);

    constant CLK_PERIOD : time := 20 ns;

begin

    UUT: second_order_system
        generic map(
            A1 => 30000,   
            A2 => -10000,  
            B  => 2000
        )
        port map(
            q_clk   => q_clk,
            reset   => reset,
            enable  => enable,
            sys_in => sys_in,
            dir     => dir,
            sys_out => sys_out
        );

    -- Clock generation
    clk_process: process
    begin
        q_clk <= '0';
        wait for CLK_PERIOD/2;
        q_clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset for the first 100 ns
        wait for 100 ns;
        reset <= '0';

        -- Wait some time before applying the step input
        wait for 200 ns;

        -- Apply a step: For example, set sys_in to 1000 and direction forward
        sys_in <= to_signed(2000, 16);
        dir <= "01";  -- forward

        -- Let the system run and observe how sys_out changes over time.
        wait for 6000 ns;

        -- Finish simulation
        wait;
    end process;

end Behavioral;
```

## Tesztelés

# Üzembe helyezés