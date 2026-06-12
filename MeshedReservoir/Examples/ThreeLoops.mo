within MeshedReservoir.Examples;
model ThreeLoops "Three reservoir loops connected"
  extends Modelica.Icons.Example;

  parameter Integer conInd = 1
    "Index for configuration (1: highPressure, 2: idealPressure, 3: lowPressure)";

  parameter Modelica.Units.SI.AbsolutePressure pMax=18E5
    "Maximum pressure, above which the simulation stops with an assertion"
    annotation(Dialog(group="Static pressures"));
  parameter Modelica.Units.SI.AbsolutePressure pMin=2E5
    "Minimum pressure, below which the simulation stops with an assertion"
    annotation(Dialog(group="Static pressures"));
  parameter Modelica.Units.SI.AbsolutePressure p_start=
    if configuration == MeshedReservoir.Configuration.highPressure then
      3E5
    elseif configuration == MeshedReservoir.Configuration.idealPressure then
      3E5
    else
      14E5
    "Start value of pressure"
    annotation(Dialog(group="Static pressures"));

  parameter Modelica.Units.SI.Mass mTot_start = 3*2065.16
    "Total mass of all expansion vessels at start of simulation. Added manually due to conditionally removed components";

  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal = 685
    "Design mass flow rate";


  parameter MeshedReservoir.Configuration configuration =
    if conInd == 1 then
      MeshedReservoir.Configuration.highPressure
    elseif conInd == 2 then
      MeshedReservoir.Configuration.idealPressure
    else
      MeshedReservoir.Configuration.lowPressure
    "Configuration of all loops";

  parameter Real pumSch_2[:,:]=[
    0.0*3600, 0;
    0.5*3600, 0;
    1.0*3600, m_flow_nominal;
    2.0*3600, m_flow_nominal;
    2.5*3600, 0;
    3.5*3600, 0;
    4.0*3600, m_flow_nominal;
    5.0*3600, m_flow_nominal;
    5.5*3600, 0;
    6.0*3600, 0]
    "Control schedule";

  parameter Real pumSch_13[:,:]=[
    0.0*3600, 0;
    0.5*3600, 0;
    1.0*3600, m_flow_nominal;
    5.0*3600, m_flow_nominal;
    5.5*3600, 0;
    6.0*3600, 0]
    "Control schedule";

  SingleLoop loo1(
    final pMax=pMax,
    final pMin=pMin,
    final p_start=p_start,
    m_flow_nominal=m_flow_nominal,
    pumSch=pumSch_13,
    isMaster=true,
    mSetAll=mTot_start,
    configuration=configuration)
    "First loop"
    annotation (Placement(transformation(extent={{-26,-60},{10,-38}})));

  SingleLoop loo2(
    final pMax=pMax,
    final pMin=pMin,
    final p_start=p_start,
    m_flow_nominal=m_flow_nominal,
    pumSch=pumSch_2,
    isMaster=false,
    mSetAll=mTot_start,
    configuration=configuration,
    addHeat=true)
    "Second loop"
    annotation (Placement(transformation(extent={{-26,-20},{10,2}})));

  SingleLoop loo3(
    final pMax=pMax,
    final pMin=pMin,
    final p_start=p_start,
    m_flow_nominal=m_flow_nominal,
    pumSch=pumSch_13,
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
      StopTime=216000,
      Tolerance=1e-06,
      __Dymola_Algorithm="Cvode"),
    __Dymola_Commands(file="modelica://MeshedReservoir/Resources/Scripts/Dymola/Examples/ThreeLoops.mos"
        "Simulate and plot"),
    Icon(coordinateSystem(preserveAspectRatio=false)),
    Diagram(coordinateSystem(preserveAspectRatio=false)));
end ThreeLoops;
