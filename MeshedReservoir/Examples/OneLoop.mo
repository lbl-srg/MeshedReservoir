within MeshedReservoir.Examples;
model OneLoop "Single reservoir loop"
  extends Modelica.Icons.Example;
  parameter Modelica.Units.SI.Mass mTot_start = 2065.16
    "Total mass of expansion vessel at start of simulation. Added manually due to conditionally removed components";

  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal = 685
    "Design mass flow rate";

  parameter Real pumSchRamp[:,:]=[
    3600, 0;
    7200, m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  parameter Real pumSchDip[:,:]=[
    0, m_flow_nominal;
    3600, m_flow_nominal;
    3600+900, 0;
    3600+1800, 0;
    7200, m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  parameter Real pumSchOn[:,:]=[
    0, m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  parameter Real pumSch[:,:] = pumSchRamp
    "Control schedule for pump";
  SingleLoop loo1(
    dpJun_nominal=1000,
    configuration=MeshedReservoir.Configuration.highPressure,
    pumSch=pumSch,
    m_flow_nominal=m_flow_nominal,
    isMaster=true,
    mSetAll=mTot_start,
    QWasHea_nominal=0)
    "Single loop"
    annotation (Placement(transformation(extent={{-18,-10},{18,12}})));

  Buildings.Controls.OBC.CDL.Integers.Sources.Constant conWasHea(k=0)
    "Set waste heat to 0"
    annotation (Placement(transformation(extent={{-60,-20},{-40,0}})));
equation
  connect(loo1.m, loo1.mAll) annotation (Line(points={{19,6},{24,6},{24,-20},{-26,
          -20},{-26,0},{-20,0}},         color={0,0,127}));
  connect(conWasHea.y, loo1.ySetWasHea) annotation (Line(points={{-38,-10},{-30,
          -10},{-30,-6},{-20,-6}}, color={255,127,0}));
  annotation (    experiment(
      StopTime=10800,
      Tolerance=1e-05,
    __Dymola_Algorithm="Cvode"),
    __Dymola_Commands(file="modelica://MeshedReservoir/Resources/Scripts/Dymola/Examples/OneLoop.mos"
        "Simulate and plot"),
    Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end OneLoop;
