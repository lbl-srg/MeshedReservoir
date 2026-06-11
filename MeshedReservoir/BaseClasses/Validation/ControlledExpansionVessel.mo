within MeshedReservoir.BaseClasses.Validation;
model ControlledExpansionVessel
  "Validation model for ExpansionVessel"
  extends Modelica.Icons.Example;

  package MediumWat = Buildings.Media.Specialized.Water.TemperatureDependentDensity
    "Medium model for water";
  package MediumAir = Modelica.Media.Air.SimpleAir
    "Medium model for air";

  MeshedReservoir.BaseClasses.ControlledExpansionVessel exp1(
    redeclare package Medium = MediumWat,
    redeclare package MediumAir = MediumAir,
    isMaster=true,
    VTot=1,
    p_start=300000,
    mSetAll=2*0.5*1000)  "Expansion vessel"
    annotation (Placement(transformation(extent={{20,12},{40,32}})));

  MeshedReservoir.BaseClasses.ControlledExpansionVessel exp2(
    redeclare package Medium = MediumWat,
    redeclare package MediumAir = MediumAir,
    isMaster=false,
    VTot=1,
    p_start=300000,
    mSetAll=2*0.5*1000)  "Expansion vessel"
    annotation (Placement(transformation(extent={{68,12},{88,32}})));

  Buildings.Fluid.Sources.MassFlowSource_T sou(
    redeclare package Medium = MediumWat,
    use_m_flow_in=true,
    m_flow=0.1,
    T=293.15,
    nPorts=1) "Mass flow source"
    annotation (Placement(transformation(extent={{-40,-8},{-20,12}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.TimeTable timTab(
    table=[
      0,0;
      1,0.2;
      2,0;
      3,-0.2;
      4,0],
    smoothness=Buildings.Controls.OBC.CDL.Types.Smoothness.ConstantSegments,
    extrapolation=Buildings.Controls.OBC.CDL.Types.Extrapolation.HoldLastPoint,
    timeScale=3600)
    "Time schedule: 0 for t=0...60s, 1 for t=60...120s, then 0"
    annotation (Placement(transformation(extent={{-80,0},{-60,20}})));

  Buildings.Controls.OBC.CDL.Reals.Add mTot(
    u1(unit="kg"),
    u2(unit="kg"),
    y(unit="kg"))
    "Total mass of all expansion vessels"
    annotation (Placement(transformation(extent={{-20,40},{0,60}})));

equation
  connect(timTab.y[1], sou.m_flow_in)
    annotation (Line(points={{-58,10},{-42,10}}, color={0,0,127}));
  connect(sou.ports[1], exp1.portWat)
    annotation (Line(points={{-20,2},{30,2},{30,12}},   color={0,127,255}));
  connect(exp2.portWat, exp1.portWat) annotation (Line(points={{78,12},{78,2},{
          30,2},{30,12}},  color={0,127,255}));
  connect(exp1.m, mTot.u1)
    annotation (Line(points={{41,13},{46,13},{46,70},{-28,70},{-28,56},{-22,56}},
                                                       color={0,0,127}));
  connect(exp2.m, mTot.u2)
    annotation (Line(points={{89,13},{94,13},{94,80},{-32,80},{-32,44},{-22,44}},
                                                       color={0,0,127}));
  connect(mTot.y, exp1.mAll)
    annotation (Line(points={{2,50},{10,50},{10,22},{18,22}},  color={0,0,127}));
  connect(mTot.y, exp2.mAll)
    annotation (Line(points={{2,50},{60,50},{60,22},{66,22}},
                                                       color={0,0,127}));
  annotation (
    Documentation(info="<html>
<p>
This model validates the <a href=\"modelica://MeshedReservoir.BaseClasses.ControlledExpansionVessel\">
MeshedReservoir.BaseClasses.ControlledExpansionVessel</a>
</p>
</html>"),
    experiment(
      StopTime=18000,
      Tolerance=1e-06,
      __Dymola_Algorithm="Cvode"),
    __Dymola_Commands(file="modelica://MeshedReservoir/Resources/Scripts/Dymola/BaseClasses/Validation/ControlledExpansionVessel.mos"
        "Simulate and plot"));
end ControlledExpansionVessel;
