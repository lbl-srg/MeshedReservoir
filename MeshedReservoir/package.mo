within ;
package MeshedReservoir "Library for meshed reservoir networks"

  type Configuration = enumeration(
    highPressure "High pressure configuration with pump and expansion vessel upstream",
    idealPressure "Ideal pressure configuration with pump downstream and expansion vessel upstream",
    lowPressure "Low pressure configuration with pump and expansion vessel downstream")
    "Enumeration for reservoir loop configuration";

annotation(
uses(
  Modelica(version="4.1.0"),
  Buildings(version="13.0.0")));

end MeshedReservoir;
