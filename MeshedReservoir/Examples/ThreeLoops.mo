within MeshedReservoir.Examples;
model ThreeLoops "Three reservoir loops connected"
  extends Modelica.Icons.Example;
  parameter Modelica.Units.SI.Mass mTot_start = 3*2065.16
    "Total mass of all expansion vessels at start of simulation. Added manually due to conditionally removed components";

  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal = 685
    "Design mass flow rate";

  parameter Real pumSchRam[:,:]=[
    3600, 0;
    7200, m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  parameter Real pumSchDip[:,:]=[
    0, m_flow_nominal;
    3600, m_flow_nominal;
    3600+1200, 0;
    3600+2400, 0;
    7200, m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  parameter Real pumSchOn[:,:]=[
    0, m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  parameter Integer pumSchInd = 1
    "Index for pump schedule";

  parameter Real pumSch[:,:] =
    if pumSchInd == 1 then
      pumSchRam
    elseif pumSchInd == 2 then
      pumSchDip
    else
      pumSchOn
    "Control schedule for pump";

  parameter Integer conInd = 1
    "Index for configuration (1: highPressure, 2: idealPressure, 3: lowPressure)";

  parameter MeshedReservoir.Configuration configuration =
    if conInd == 1 then
      MeshedReservoir.Configuration.highPressure
    elseif conInd == 2 then
      MeshedReservoir.Configuration.idealPressure
    else
      MeshedReservoir.Configuration.lowPressure
    "Configuration of all loops";

  SingleLoop loo1(
    m_flow_nominal=m_flow_nominal,
    pumSch=pumSch,
    isMaster=true,
    mSetAll=mTot_start,
    configuration=configuration)
    "First loop"
    annotation (Placement(transformation(extent={{-26,-60},{10,-38}})));

  SingleLoop loo2(
    m_flow_nominal=m_flow_nominal,
    pumSch=pumSch,
    isMaster=false,
    mSetAll=mTot_start,
    configuration=configuration)
    "Second loop"
    annotation (Placement(transformation(extent={{-26,-20},{10,2}})));

  SingleLoop loo3(
    m_flow_nominal=m_flow_nominal,
    pumSch=pumSch,
    isMaster=false,
    mSetAll=mTot_start,
    configuration=configuration)
    "Third loop"
    annotation (Placement(transformation(extent={{-26,20},{10,42}})));

  Buildings.Controls.OBC.CDL.Reals.MultiSum mTotOth(nin=3)
    "Total mass of all expansion vessels"
    annotation (Placement(transformation(extent={{40,-60},{60,-40}})));
equation
  connect(loo2.port_4, loo1.port_1)
    annotation (Line(points={{-10,-20},{-10,-38}}, color={0,127,255}));
  connect(loo2.port_3, loo1.port_2)
    annotation (Line(points={{-6,-20},{-6,-38}},   color={0,127,255}));
  connect(loo3.port_4, loo2.port_1)
    annotation (Line(points={{-10,20},{-10,2}}, color={0,127,255}));
  connect(loo3.port_3, loo2.port_2)
    annotation (Line(points={{-6,20},{-6,2}},   color={0,127,255}));
  connect(loo1.m, mTotOth.u[1]) annotation (Line(points={{11,-44},{28,-44},{28,
          -50.6667},{38,-50.6667}},
                          color={0,0,127}));
  connect(loo2.m, mTotOth.u[2]) annotation (Line(points={{11,-4},{28,-4},{28,-42},
          {30,-42},{30,-50},{38,-50}}, color={0,0,127}));
  connect(loo3.m, mTotOth.u[3]) annotation (Line(points={{11,36},{28,36},{28,
          -49.3333},{38,-49.3333}},
                          color={0,0,127}));
  connect(mTotOth.y, loo3.mAll) annotation (Line(points={{62,-50},{70,-50},{70,
          -80},{-50,-80},{-50,30},{-28,30}},
                                        color={0,0,127}));
  connect(mTotOth.y, loo2.mAll) annotation (Line(points={{62,-50},{70,-50},{70,-80},
          {-50,-80},{-50,-10},{-28,-10}}, color={0,0,127}));
  connect(mTotOth.y, loo1.mAll) annotation (Line(points={{62,-50},{70,-50},{70,
          -80},{-50,-80},{-50,-50},{-28,-50}},
                                          color={0,0,127}));
  annotation (experiment(
      StopTime=10800,
      Tolerance=1e-05,
      __Dymola_Algorithm="Cvode"),
    __Dymola_Commands(file="modelica://MeshedReservoir/Resources/Scripts/Dymola/Examples/ThreeLoops.mos"
        "Simulate and plot"),
    Icon(coordinateSystem(preserveAspectRatio=false)),
    Diagram(coordinateSystem(preserveAspectRatio=false)));
end ThreeLoops;
