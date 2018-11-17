public class I_NOP extends JatmeInstruction {
  public boolean extraWord() {
    return false;
  }
  public boolean execute(JatmeX8 state, int relativeCycle) {
    return true;
  }
}
