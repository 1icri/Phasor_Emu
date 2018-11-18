public class Jatme {
  JatmeModel model;
  int pc;
  int flashSize;
  byte sreg;
  byte[] memFlash;
  JatmeInstruction[] compiledInstructions;
  byte[] memEeprom;
  byte[] memSram;
  byte fuseLow = (byte)0x62;
  byte fuseHigh = (byte)0xDF;
  byte fuseExt;
  JatmeInstruction instructionReg;
  int eepromSingleOpMicros = 1800; // Time to erase or write
  int eepromDualOpMicros = 3400; // Time to erase AND write (atomic operation)
  int eepromSingleOpCycles;
  int eepromDualOpCycles;
  int eepromOpTimer;
  int flashWriteMicros = 4100; // Time for flash write
  int flashWriteCycles;
  int flashWriteTimer;
  int externalClock;
  int internalClockHigh = 8000000; // Internal 8MHz clock
  int internalClockLow = 128000; // Internal 128kHz clock
  int currentClock;
  boolean clockOutB0;
  boolean clockPrescalerChangeEnable;
  int clockPrescaler;
  JatmeClockSelection clockSelect;

  public Jatme(JatmeModel model, int externalClock, byte fuseLow, byte fuseHigh, byte fuseExt) {
    this.model = model;
    this.externalClock = externalClock;
    this.fuseLow = fuseLow;
    this.fuseHigh = fuseHigh;
    this.fuseExt = fuseExt;
    initClockPrescaler(fuseLow);
    memFlash = new byte[model.flashPages*model.flashPageSize];
    compiledInstructions = new JatmeInstruction[memFlash.length/2];
    memEeprom = new byte[model.eepromSize];
    memSram = new byte[256 + model.sramSize];
    //eepromSingleOpCycles = model.();
    instructionReg = null;
  }
  
  public int getCurrentClock(){
    return currentClock;
  }
  public void initClockPrescaler(byte fuseLow){
    boolean ckdiv8 = (fuseLow&0x80)==0;
    int clockPrescalerSel = ckdiv8 ? 3 : 0;
    clockSelect = JatmeClockSelection.fromCkSel(fuseLow&0x0F);
    clockOutB0 = (fuseLow&0x40)==0;
    clockPrescalerChangeEnable=false;
    clockPrescaler = 1 << clockPrescalerSel;
  }
  
  // Writes flash contents all at once, no erase and no page operations emulated.
  public void programFlash(byte[] program) {
    for (int i=0; i<min(memFlash.length, program.length); i++) {
      setFlash(i, program[i], false);
    }
  }

  public void recompileForPage(int page) {
    int offset = model.flashPageSize * page;
    for (int i=-2; i<model.flashPageSize; i+=2) {
      recompileInstruction(offset);
    }
  }

  public void recompileInstruction(int address) {
    int wordAddr = address - (address&1); // Align to word
    int thisWord = (((int)getFlash(wordAddr+0) << 8)) | getFlash(wordAddr+1);
    int nextWord = (((int)getFlash(wordAddr+1) << 8)) | getFlash(wordAddr+1);
    JatmeInstruction inst = instructionFromWords(thisWord,nextWord); 
  }

  // Memory write methods
  public void setFlash(int address, byte value, boolean recompile) {
    //
    memFlash[address]=value;
    if (recompile) {
    }
  }
  public void setEeprom(int address, byte value) {
    memEeprom[address]=value;
  }
  public void setRawSram(int address, byte value) {
    memSram[address]=value;
  }
  public void setRegGeneral(int address, byte value) {
    memSram[address&31]=value;
  }
  public void setRegIo(int address, byte value) {
    memSram[(address&63)+32]=value;
  }
  public void setRegExtIo(int address, byte value) {
    memSram[(address&255)+96]=value;
  }
  public void setSram(int address, byte value) {
    memSram[(address & (model.sramSize-1)) + 256]=value;
  }
  // Memory read methods
  public byte getFlash(int address){
    return memFlash[address];
  }
  public byte getEeprom(int address){
    return memEeprom[address];
  }
  public byte getRawSram(int address) {
    return memSram[address];
  }
  public byte getRegGeneral(int address) {
    return memSram[address&31];
  }
  public byte getRegIo(int address) {
    return memSram[(address&63)+32];
  }
  public byte getRegExtIo(int address) {
    return memSram[(address&255)+96];
  }
  public byte getSram(int address) {
    return memSram[(address & (model.sramSize-1)) + 256];
  }

  public JatmeInstruction instructionFromWords(int word1,int word2) {
    JatmeInstruction inst;
    inst = new I_NOP();
    return inst;
  }
  public void clock() {
  }
}
public abstract class JatmeModel {
  // Must all be powers of two!
  public int flashPageSize; // Bytes in one page in flash
  public int flashPages; // Total number of pages in flash
  public int eepromSize; // Total bytes in EEPROM
  public int sramSize; // Total bytes in SRAM
  
  // Timing
  public int eepromSingleOpMicros; // Time for EEPROM to erase OR program separately
  public int eepromDualOpMicros; // Time for EEPROM to erase AND then program in one operation
  public int flashWriteMicros; // Time for flash erase or program operation
  
  // Interrupt vector sizing
  public int interruptVectorShift; // Bits to shift interrupt vectors left by
  
  // Extended fuse byte handling
  public byte defaultFuseExt;
  public abstract boolean selfPrgEn(byte fuseExt); // Self program enable, true if unused
  public abstract boolean bootRst(byte fuseExt); // Use boot area reset vector, false if unused
  public abstract int bootSz(byte fuseExt); // Boot area size, 0 if unused
}
public class Jatme48P extends JatmeModel {
  public int flashPageSize = 32;
  public int flashPages = 64;
  public int eepromSize = 256;
  public int sramSize = 512;
  public int interruptVectorShift = 0;
  public byte defaultFuseExt = (byte)0xFF;
  public boolean selfPrgEn(byte fuseExt) {
    return (fuseExt&1)==0;
  }
  public boolean bootRst(byte fuseExt) {
    return false;
  }
  public int bootSz(byte fuseExt) {
    return 0;
  }
}
public class Jatme88P extends JatmeModel {
  public int flashPageSize = 32;
  public int flashPageBits = 128;
  public int eepromSize = 512;
  public int sramSize = 1024;
  public int interruptVectorShift = 1;
  public byte defaultFuseExt = (byte)0xF9;
  public boolean selfPrgEn(byte fuseExt) {
    return true;
  }
  public boolean bootRst(byte fuseExt) {
    return (fuseExt&1)==0;
  }
  public int bootSz(byte fuseExt) {
    return 2048>>((int)(fuseExt&6)>>1);
  }
}
public abstract class JatmeInstruction {
  // Returns true if the instruction uses a second word.
  public abstract boolean extraWord();
  // Returns true when finished
  // Otherwise called again next cycle with relativeCycle incremented
  public abstract boolean execute(Jatme state, int relativeCycle);
}
public enum JatmeClockSelection {
  EXTERNAL_SIGNAL,
  INTERNAL_HIGH,
  INTERNAL_LOW,
  EXTERNAL_CRYSTAL;
  public static JatmeClockSelection fromCkSel(int cksel){
    int sel = cksel & 15;
    if(sel <= 1) return EXTERNAL_SIGNAL; // Include cksel = 0 ('reserved') as no way to handle reserved modes
    if(sel == 2) return INTERNAL_HIGH;
    if(sel == 3) return INTERNAL_LOW;
    return EXTERNAL_CRYSTAL;
  }
}
