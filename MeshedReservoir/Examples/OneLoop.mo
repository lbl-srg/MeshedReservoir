within MeshedReservoir.Examples;
model OneLoop "Single reservoir loop"
  extends Modelica.Icons.Example;
  parameter Modelica.Units.SI.Mass mTot_start = 2065.16
    "Total mass of expansion vessel at start of simulation. Added manually due to conditionally removed components";

  SingleLoop loo1(
    isMaster=true,
    mSetAll=mTot_start)
    "Single loop"
    annotation (Placement(transformation(extent={{-32,-60},{4,-38}})));

equation
  connect(loo1.m, loo1.mAll) annotation (Line(points={{5,-44},{10,-44},{10,-70},{
          -40,-70},{-40,-50},{-34,-50}}, color={0,0,127}));
  annotation (    experiment(
      StopTime=10800,
      Tolerance=1e-05,
    __Dymola_Algorithm="Cvode"),
    __Dymola_Commands(file="modelica://MeshedReservoir/Resources/Scripts/Dymola/Examples/OneLoop.mos"
        "Simulate and plot"),
    Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end OneLoop;