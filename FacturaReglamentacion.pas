(******************************************************************************
 PROYECTO FACTURACION ELECTRONICA
 Copyright (C) 2010-2014 - Bambu Code SA de CV - Ing. Luis Carrasco

 Metodos para validar los diferentes tipos de datos y como deben de estar
 especificados en el archivo XML.

 Este archivo pertenece al proyecto de codigo abierto de Bambu Code:
 http://bambucode.com/codigoabierto

 La licencia de este codigo fuente se encuentra en:
 http://github.com/bambucode/tfacturaelectronica/blob/master/LICENCIA
 ******************************************************************************)
unit FacturaReglamentacion;

interface

type

  TFEReglamentacion = class
  private
      class procedure CorregirConfiguracionRegionalLocal;
      class procedure RegresarConfiguracionRegionalLocal;
  public
      /// <summary>Convierte el valor de moneda al formato de dinero requerido por el SAT
      /// </summary>
      /// <param name="Monto">Monto a convertir al formato aceptado por el SAT</param>
      class function ComoMoneda(dMonto: Currency; const aDecimalesDefault: Integer = 6): String;
      class function ComoCadena(sCadena: String) : String;
      class function ComoCantidad(dCantidad: Double) : String;
      class function ComoFechaHora(dtFecha: TDateTime) : String;
      class function DeFechaHoraISO8601(const aFechaISO8601: String) : TDateTime;
      class function ComoFechaAduanera(dtFecha: TDateTime) : String;
      class function ComoTasaImpuesto(dTasa: Double; const aDecimalesDefault: Integer
          = 6): String;
      class function ComoDateTime(sFechaISO8601: String): TDateTime;
      class function ComoFechaHoraInforme(dtFecha: TDateTime) : String;
      class function DeTasaImpuesto(const aCadenaTasa: String) : Double;
      class function DeCantidad(const aCadenaCatidad: String) : Double;
      class function DeMoneda(const aMoneda : String) : Currency;
      class function ComoLetras(const aImporte: Currency) : String;
  end;

var
  separadorDecimalAnterior: Char;

implementation

uses DateUtils,
     {$IF Compilerversion >= 20}
     Soap.XSBuiltIns,
     {$ELSE}
     XSBuiltIns,
     {$IFEND}
     SysUtils;


class procedure TFEReglamentacion.CorregirConfiguracionRegionalLocal;
begin
  // Debido a que si el usuario en la PC tiene una configuración regional incorrecta
  // los XMLs se generan con montos y cantidades inválidas
  separadorDecimalAnterior := DecimalSeparator;
  // Indicamos que el separador Decimal será el punto
  DecimalSeparator := '.';
end;

class procedure TFEReglamentacion.RegresarConfiguracionRegionalLocal;
begin
  DecimalSeparator := separadorDecimalAnterior;
end;

// Segun las reglas del SAT:
// "Se expresa en la forma aaaa-mm-ddThh:mm:ss, de acuerdo con la especificación ISO 8601"
class function TFEReglamentacion.ComoFechaHora(dtFecha: TDateTime) : String;
begin
  Result := FormatDateTime('yyyy-mm-dd', dtFecha) + 'T' + FormatDateTime('hh:nn:ss', dtFecha);
end;

class function TFEReglamentacion.DeFechaHoraISO8601(const aFechaISO8601: String) : TDateTime;
begin
  // Ref: http://stackoverflow.com/questions/6651829/how-do-i-convert-an-iso-8601-string-to-a-delphi-tdate
  with TXSDateTime.Create() do
  try
    XSToNative(aFechaISO8601);
    Result := AsUTCDateTime;
  finally
    Free;
  end;
end;

// Regresa la fecha/hora en el formato del Informe Mensual
class function TFEReglamentacion.ComoFechaHoraInforme(dtFecha: TDateTime) : String;
begin
  Result := FormatDateTime('dd/mm/yyyy', dtFecha) + ' ' + FormatDateTime('hh:nn:ss', dtFecha);
  {$IFDEF DEBUG}
      Assert(Length(Result) = 19, 'La longitud de la fecha del informe no fue de 19 caracteres!');
  {$ENDIF}
end;

// Convierte una fecha de ISO 8601 (formato del XML) a TDateTime usado en Delphi.
class function TFEReglamentacion.ComoDateTime(sFechaISO8601: String): TDateTime;
var
    sAno, sMes, sDia, sHora, sMin, sMs: String;
begin
    // Ejemplo: 2009-08-16T16:30:00
    sAno := Copy(sFechaISO8601, 1, 4);
    sMes := Copy(sFechaISO8601, 6, 2);
    sDia := Copy(sFechaISO8601, 9, 2);
    sHora := Copy(sFechaISO8601, 12, 2);
    sMin := Copy(sFechaISO8601, 15, 2);
    sMs := Copy(sFechaISO8601, 18, 2);
    Result := EncodeDateTime(StrToInt(sAno), StrToInt(sMes), StrToInt(sDia), StrToInt(sHora),
                              StrToInt(sMin), StrToInt(sMs), 0);
end;

class function TFEReglamentacion.ComoFechaAduanera(dtFecha: TDateTime) : String;
begin
   // Formato sacado del CFDv2.XSD: "Atributo requerido para expresar la fecha de expedición
   // del documento aduanero que ampara la importación del bien. Se expresa en el formato aaaa-mm-dd"
   Result := FormatDateTime('yyyy-mm-dd', dtFecha);
end;

class function TFEReglamentacion.ComoMoneda(dMonto: Currency; const
    aDecimalesDefault: Integer = 6): String;
begin
   // Regresamos los montos de monedas con 6 decimales (maximo permitido en el XSD)
   // http://www.sat.gob.mx/cfd/3/cfdv32.xsd
   // http://www.sat.gob.mx/cfd/2/cfdv22.xsd
   try
      CorregirConfiguracionRegionalLocal;
      Result:=CurrToStrF(dMonto, ffFixed, aDecimalesDefault);
   finally
      RegresarConfiguracionRegionalLocal;
   end;
end;

class function TFEReglamentacion.ComoTasaImpuesto(dTasa: Double; const
    aDecimalesDefault: Integer = 6): String;
begin
   // Regresamos los montos de monedas con 6 decimales (maximo permitido en el XSD)
   // http://www.sat.gob.mx/cfd/3/cfdv32.xsd
   // http://www.sat.gob.mx/cfd/2/cfdv22.xsd
   try
     CorregirConfiguracionRegionalLocal;
     Result:=FloatToStrF(dTasa,ffFixed, 10, aDecimalesDefault);
   finally
     RegresarConfiguracionRegionalLocal;
   end;
end;

class function TFEReglamentacion.DeTasaImpuesto(const aCadenaTasa: String) : Double;
begin
  Result := TFEReglamentacion.DeCantidad(aCadenaTasa);
end;

class function TFEReglamentacion.DeCantidad(const aCadenaCatidad: String) : Double;
begin
  try
     CorregirConfiguracionRegionalLocal;
     Result:=StrToFloat(aCadenaCatidad);
  finally
     RegresarConfiguracionRegionalLocal;
  end;
end;

class function TFEReglamentacion.DeMoneda(const aMoneda : String) : Currency;
begin
  try
     CorregirConfiguracionRegionalLocal;
     Result:=StrToCurr(aMoneda);
  finally
     RegresarConfiguracionRegionalLocal;
  end;
end;

// Las cadenas usadas en el XML deben de escapar caracteres incorrectos
// Ref: http://dof.gob.mx/nota_detalle.php?codigo=5146699&fecha=15/06/2010
class function TFEReglamentacion.ComoCadena(sCadena: String) : String;
var
   sCadenaEscapada: String;
begin
    sCadenaEscapada:=sCadena;
    // Las siguientes validaciones las omitimos ya que las mismas clases
    // de Delphi lo hacen por nosotros:
    // En el caso del & se deberá usar la secuencia &amp;
    // En el caso del “ se deberá usar la secuencia &quot;
    // En el caso del < se deberá usar la secuencia &lt;
    // En el caso del > se deberá usar la secuencia &gt;
    // En el caso del ‘ se deberá usar la secuencia &apos;

    // No es permitido el caracter de | en las cadenas (entra en conflicto con la generación de la Cadena Original)
    sCadenaEscapada := StringReplace(sCadenaEscapada, '|', '', [rfReplaceAll]);

    // Si se presentan nuevas reglas para los Strings en el XML, incluirlas aqui

    Result:=sCadenaEscapada;
end;

class function TFEReglamentacion.ComoCantidad(dCantidad: Double) : String;
begin
   // Las cantidades cerradas las regresamos sin decimales
   // las que tienen fracciones con 2 digitos decimales...
   try
     CorregirConfiguracionRegionalLocal;
     if Frac(dCantidad) > 0 then
        Result:=FloatToStrF(dCantidad,ffFixed,10,2)
     else
        Result:=IntToStr(Round(dCantidad));
   finally
     RegresarConfiguracionRegionalLocal;
   end;
end;

class function TFEReglamentacion.ComoLetras(const aImporte: Currency) : String;
const
  iTopFil: Smallint = 6;
  iTopCol: Smallint = 10;
  aCastellano: array [0 .. 5, 0 .. 9] of PChar = (('UNA ', 'DOS ', 'TRES ',
    'CUATRO ', 'CINCO ', 'SEIS ', 'SIETE ', 'OCHO ', 'NUEVE ', 'UN '),
    ('ONCE ', 'DOCE ', 'TRECE ', 'CATORCE ', 'QUINCE ', 'DIECISEIS ',
    'DIECISIETE ', 'DIECIOCHO ', 'DIECINUEVE ', ''),
    ('DIEZ ', 'VEINTE ', 'TREINTA ', 'CUARENTA ', 'CINCUENTA ', 'SESENTA ',
    'SETENTA ', 'OCHENTA ', 'NOVENTA ', 'VEINTI'),
    ('CIEN ', 'DOSCIENTAS ', 'TRESCIENTAS ', 'CUATROCIENTAS ', 'QUINIENTAS ',
    'SEISCIENTAS ', 'SETECIENTAS ', 'OCHOCIENTAS ', 'NOVECIENTAS ', 'CIENTO '),
    ('CIEN ', 'DOSCIENTOS ', 'TRESCIENTOS ', 'CUATROCIENTOS ', 'QUINIENTOS ',
    'SEISCIENTOS ', 'SETECIENTOS ', 'OCHOCIENTOS ', 'NOVECIENTOS ', 'CIENTO '),
    ('MIL ', 'MILLON ', 'MILLONES ', 'CERO ', 'Y ', 'UNO ', 'DOS ', 'CON ',
    '', ''));
const
  _MODO_MASCULINO = 1;
var
  aTexto: array [0 .. 5, 0 .. 9] of PChar;
  cTexto, cNumero: String;
  iCentimos, iPos: Smallint;
  bHayCentimos, bHaySigni: Boolean;

  (* *********************************** *)
  (* Cargar Textos según Idioma / Modo *)
  (* *********************************** *)

  procedure NumLetra_CarTxt;
  var
    i, j: Smallint;
  begin
    (* Asignación según Idioma *)

    for i := 0 to iTopFil - 1 do
      for j := 0 to iTopCol - 1 do
        aTexto[i, j] := aCastellano[i, j];

    (* Asignación si Modo Masculino *)
    for j := 0 to 1 do
        aTexto[0, j] := aTexto[5, j + 5];

    for j := 0 to 9 do
      aTexto[3, j] := aTexto[4, j];
  end;

(* ************************** *)
(* Traducir Dígito -Unidad- *)
(* ************************** *)

  procedure NumLetra_Unidad;
  begin
    if not((cNumero[iPos] = '0') or (cNumero[iPos - 1] = '1') or
      ((Copy(cNumero, iPos - 2, 3) = '001') and ((iPos = 3) or (iPos = 9))))
    then
      if (cNumero[iPos] = '1') and (iPos <= 6) then
        cTexto := cTexto + aTexto[0, 9]
      else
        cTexto := cTexto + aTexto[0, StrToInt(cNumero[iPos]) - 1];

    if ((iPos = 3) or (iPos = 9)) and (Copy(cNumero, iPos - 2, 3) <> '000') then
      cTexto := cTexto + aTexto[5, 0];

    if (iPos = 6) then
      if (Copy(cNumero, 1, 6) = '000001') then
        cTexto := cTexto + aTexto[5, 1]
      else
        cTexto := cTexto + aTexto[5, 2];
  end;

(* ************************** *)
(* Traducir Dígito -Decena- *)
(* ************************** *)

  procedure NumLetra_Decena;
  begin
    if (cNumero[iPos] = '0') then
      Exit
    else if (cNumero[iPos + 1] = '0') then
      cTexto := cTexto + aTexto[2, StrToInt(cNumero[iPos]) - 1]
    else if (cNumero[iPos] = '1') then
      cTexto := cTexto + aTexto[1, StrToInt(cNumero[iPos + 1]) - 1]
    else if (cNumero[iPos] = '2') then
      cTexto := cTexto + aTexto[2, 9]
    else
      cTexto := cTexto + aTexto[2, StrToInt(cNumero[iPos]) - 1] + aTexto[5, 4];
  end;

(* *************************** *)
(* Traducir Dígito -Centena- *)
(* *************************** *)

  procedure NumLetra_Centena;
  var
    iPos2: Smallint;
  begin
    if (cNumero[iPos] = '0') then
      Exit;

    iPos2 := 4 - Ord(iPos > 6);

    if (cNumero[iPos] = '1') and (Copy(cNumero, iPos + 1, 2) <> '00') then
      cTexto := cTexto + aTexto[iPos2, 9]
    else
      cTexto := cTexto + aTexto[iPos2, StrToInt(cNumero[iPos]) - 1];
  end;

(* ************************************ *)
(* Eliminar Blancos previos a guiones *)
(* ************************************ *)

  procedure NumLetra_BorBla;
  var
    i: Smallint;
  begin
    i := Pos(' -', cTexto);

    while (i > 0) do
    begin
      Delete(cTexto, i, 1);
      i := Pos(' -', cTexto);
    end;
  end;

begin
  (* Control de Argumentos *)

  if (aImporte < 0.00) or (aImporte > 999999999999.99) then
  begin
    Result := 'ERROR EN ARGUMENTOS';
    Abort;
  end;

  (* Cargar Textos según Idioma / Modo *)

  NumLetra_CarTxt;

  (* Bucle Exterior -Tratamiento Céntimos- *)
  (* NOTA: Se redondea a dos dígitos decimales *)

  cNumero := Trim(Format('%12.0f', [Int(aImporte)]));
  cNumero := StringOfChar('0', 12 - Length(cNumero)) + cNumero;
  iCentimos := Trunc((Frac(aImporte) * 100) + 0.5);

  repeat
    (* Detectar existencia de Céntimos *)

    if (iCentimos <> 0) then
      bHayCentimos := True
    else
      bHayCentimos := False;

    (* Bucle Interior -Traducción- *)

    bHaySigni := False;

    for iPos := 1 to 12 do
    begin
      (* Control existencia Dígito significativo *)

      if not(bHaySigni) and (cNumero[iPos] = '0') then
        Continue
      else
        bHaySigni := True;

      (* Detectar Tipo de Dígito *)

      case ((iPos - 1) mod 3) of
        0:
          NumLetra_Centena;
        1:
          NumLetra_Decena;
        2:
          NumLetra_Unidad;
      end;
    end;

    (* Detectar caso 0 *)

    if (cTexto = '') then
    begin
      //cTexto := aTexto[5, 3];
      cTexto := cTexto + '' + '00/100 M.N.';
      bHayCentimos := False;
    end;

    (* Traducir Céntimos -si procede- *)

    if (iCentimos <> 0) then
    begin
      //cTexto := cTexto + aTexto[5, 7];
      cTexto := cTexto + '' + IntToStr(iCentimos) + '/100 M.N.';
      cNumero := Trim(Format('%.12d', [iCentimos]));
      iCentimos := 0;
      bHayCentimos := False;
    end;
  until not(bHayCentimos);

  (* Retornar Resultado *)

  Result := Trim(cTexto);
end;

end.