public class I_NOP extends JatmeInstruction {
  public boolean paramsFromOpcode(int word, int wordAfter) {
    return false;
  }
  public boolean execute(JatmeX8 state, int relativeCycle) {
    return true;
  }
}
