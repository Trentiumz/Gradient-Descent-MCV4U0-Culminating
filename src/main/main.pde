import java.util.*;
import java.util.stream.*;

void setup(){
  Variable a = new Variable(5, false, "slope");
  Variable b = new Variable(5, false, "bias");
  
  Variable[] x = new Variable[]{new Variable(3, true, "x1"), new Variable(5, true, "x2")};
  Variable[] y = new Variable[]{new Variable(0, true, "y1"), new Variable(6, true, "y2")};
  Variable negativeOne = new Variable(-1, true, "-1");
  
  Trans[] ax = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) ax[i] = new Product(x[i], a);
  Trans[] plusB = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) plusB[i] = new Sum(new Trans[]{ax[i], b});
  Trans[] residual = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) residual[i] = new Sum(new Trans[]{plusB[i], new Product(y[i], negativeOne)});
  Trans[] squaredResidual = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) squaredResidual[i] = new Exponent(residual[i], 2);
  Trans totResidual = new Sum(squaredResidual);
  Loss loss = new Loss(totResidual);
  
  List<Variable> allInputs = new ArrayList<Variable>(Arrays.asList(x));
  for(Variable i : y) allInputs.add(i);
  allInputs.add(negativeOne);
  allInputs.add(a);
  allInputs.add(b);
  Model model = new Model(allInputs, Arrays.asList(plusB), loss);
  model.runModel();
  System.out.println(a.getVal() + " " + a.getDerivative());
  System.out.println(b.getVal() + " " + b.getDerivative());
  model.runModel();
  System.out.println(a.getVal() + " " + a.getDerivative());
  System.out.println(b.getVal() + " " + b.getDerivative());
}

void draw(){
  
}
