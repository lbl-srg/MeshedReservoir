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
    configuration=MeshedReservoir.Configuration.highPressure,
    pumSch=pumSch,
    m_flow_nominal=m_flow_nominal,
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
