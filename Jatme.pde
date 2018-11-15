public class JatmeX8 {
  JatmeX8Model model;
  int pc;
  int flashSize;
  byte sreg;
  byte[] memFlash;
  JatmeInstruction[] compiledInstructions;
  byte[] memEeprom;
  byte[] memSram;
  JatmeInstruction instructionReg;
  int eepromSingleOpCycles; // Time to erase or write
  int eepromDualOpCycles; // Time to erase AND write (atomic operation)
  int eepromOpTimer;
  int flashWriteCycles; // Time for flash write
  int flashWriteTimer;

  public JatmeX8(JatmeX8Model model, int externalClock) {
    this.model = model;
    memFlash = new byte[model.flashPages()*model.flashPageSize()];
    compiledInstructions = new JatmeInstruction[memFlash.length/2];
    memEeprom = new byte[model.eepromSize()];
    memSram = new byte[model.memoryTotalSize()];
    //eepromSingleOpCycles = model.();
    instructionReg = null;
  }

  public void programFuseLow(byte value) {
    
  }

  // Writes flash contents all at once, no erase and no page operations emulated.
  public void programFlash(byte[] program) {
    for (int i=0; i<min(memFlash.length, program.length); i++) {
      setFlash(i, program[i], false);
    }
  }

  public void recompileForPage(int page) {
    int offset = model.flashPageSize() * page;
    for (int i=-2; i<model.flashPageSize(); i+=2) {
      recompileInstruction(offset);
    }
  }

  public void recompileInstruction(int address) {
    int wordAddr = address - (address&1); // Align to word
    int thisWord = (((int)memFlash[wordAddr+0] << 8)) | memFlash[wordAddr+1];
    int nextWord = (((int)memFlash[wordAddr+1] << 8)) | memFlash[wordAddr+1];
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
    memSram[model.mapRegGeneral(address)]=value;
  }
  public void setRegIo(int address, byte value) {
    memSram[model.mapRegIo(address)]=value;
  }
  public void setRegExtIo(int address, byte value) {
    memSram[model.mapRegExtIo(address)]=value;
  }
  public void setSram(int address, byte value) {
    memSram[model.mapSram(address)]=value;
  }
  // Memory read methods
  public byte getRawSram(int address) {
    return memSram[address];
  }
  public byte getRegGeneral(int address) {
    return memSram[model.mapRegGeneral(address)];
  }
  public byte getRegIo(int address) {
    return memSram[model.mapRegIo(address)];
  }
  public byte getRegExtIo(int address) {
    return memSram[model.mapRegExtIo(address)];
  }
  public byte getSram(int address) {
    return memSram[model.mapSram(address)];
  }

  public JatmeInstruction instructionFromOpcode(int opcode) {
    JatmeInstruction inst;
    inst = new I_NOP();
    return inst;
  }
  public void clock() {
  }
}
public abstract class JatmeX8Model {
  abstract int flashPageSize();
  abstract int flashPages();
  abstract int eepromSize();
  abstract int memoryTotalSize();
  abstract int eepromSingleOpMicros();
  abstract int eepromDualOpMicros();
  abstract int flashWriteMicros();
  abstract int interruptVectorSize();
  abstract int mapRegGeneral(int index);
  abstract int mapRegIo(int index);
  abstract int mapRegExtIo(int index);
  abstract int mapSram(int index);
}
public class Jatme48 extends JatmeX8Model {
  public int flashPageSize() {
    return 64;
  }
  public int flashPages() {
    return 64;
  }
  public int eepromSize() {
    return 256;
  }
  public int memoryTotalSize() {
    return (32+64+160+512);
  }
  public int eepromSingleOpMicros() {
    return 1800;
  }
  public int eepromDualOpMicros() {
    return 3400;
  }
  public int flashWriteMicros() {
    return 4100;
  }
  public int interruptVectorSize() {
    return 1;
  }
  public int mapRegGeneral(int index) {
    return 0+index;
  }
  public int mapRegIo(int index) {
    return 32+index;
  }
  public int mapRegExtIo(int index) {
    return 96+index;
  }
  public int mapSram(int index) {
    return 256+index;
  }
}
public class Jatme88 extends JatmeX8Model {
  public int flashPageSize() {
    return 64;
  }
  public int flashPages() {
    return 128;
  }
  public int eepromSize() {
    return 512;
  }
  public int memoryTotalSize() {
    return (32+64+160+1024);
  }
  public int eepromSingleOpMicros() {
    return 1800;
  }
  public int eepromDualOpMicros() {
    return 3400;
  }
  public int flashWriteMicros() {
    return 4100;
  }
  public int interruptVectorSize() {
    return 1;
  }
  public int mapRegGeneral(int index) {
    return 0+index;
  }
  public int mapRegIo(int index) {
    return 32+index;
  }
  public int mapRegExtIo(int index) {
    return 96+index;
  }
  public int mapSram(int index) {
    return 256+index;
  }
}
public abstract class JatmeInstruction {
  // Loads parameters from raw opcode. Returns true if word after is used.
  public abstract boolean paramsFromOpcode(int word, int wordAfter);
  // Returns true when finished 
  public abstract boolean execute(JatmeX8 state, int relativeCycle);
}
