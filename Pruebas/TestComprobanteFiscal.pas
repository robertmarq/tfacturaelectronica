(* *****************************************************************************
  Copyright (C) 2010 - Bambu Code SA de CV - Ing. Luis Carrasco

  Este archivo pertenece al proyecto de codigo abierto de Bambu Code:
  http://bambucode.com/codigoabierto

  La licencia de este codigo fuente se encuentra en:
  http://github.com/bambucode/bc_facturaelectronica/blob/master/LICENCIA
  ***************************************************************************** *)
  unit TestComprobanteFiscal;

interface

uses
  TestFramework, ComprobanteFiscal, FacturaTipos, TestPrueba;

type

  TestTFEComprobanteFiscal = class(TTestPrueba)
  strict private
    fComprobanteFiscal: TFEComprobanteFiscal;
  public
    procedure SetUp; override;
    procedure TearDown; override;

  published
      procedure Create_NuevoComprobante_GenereEstructuraXMLBasica;
      procedure setReceptor_Receptor_LoGuardeEnXML;
      procedure setEmisor_Emisor_LoGuardeEnXML;
      procedure AgregarConcepto_Concepto_LoGuardeEnXML;
      procedure setCertificado_Certificado_GuardeNumeroDeSerieEnEstructuraXML;
      procedure setFolio_Folio_LoGuardeEnXML;
      procedure setBloqueFolios_Bloque_LoGuardeEnXML;
      procedure setBloqueFolios_FolioFueraDeRango_CauseExcepcion;
  end;

implementation

uses
  Windows, SysUtils, Classes, ConstantesFixtures;

procedure TestTFEComprobanteFiscal.SetUp;
begin
   inherited;
   fComprobanteFiscal:=TFEComprobanteFiscal.Create;
end;

procedure TestTFEComprobanteFiscal.TearDown;
begin
   FreeAndNil(fComprobanteFiscal);
end;

procedure TestTFEComprobanteFiscal.AgregarConcepto_Concepto_LoGuardeEnXML;
var
   Concepto: TFEConcepto;
   sXMLConcepto : WideString;
begin
   sXMLConcepto:=leerContenidoDeFixture('comprobante_fiscal/concepto.xml');

   Concepto.Cantidad:=12.55;
   Concepto.Unidad:='pz';
   // Incluimos algunos caracteres invalidos para el XML para verificar
   // que se est�n "escapando" correctamente
   Concepto.Descripcion:='Jab�n & Jab�n Modelo <ABC>';
   Concepto.ValorUnitario:=30.50;

   fComprobanteFiscal.AgregarConcepto(Concepto);
   
   CheckEquals(sXMLConcepto, fComprobanteFiscal.fXmlComprobante.XML,
              'El concepto no fue almacenado correctamente en la estrucutr XML');
end;

procedure TestTFEComprobanteFiscal.setBloqueFolios_Bloque_LoGuardeEnXML;
var
   sXMLFixture: WideString;
   Bloque: TFEBloqueFolios;
begin
    // Leemos el contenido de nuestro 'Fixture' para comparar que sean iguales...
   sXMLFixture:=leerContenidoDeFixture('comprobante_fiscal/bloque_folios.xml');

   Bloque.NumeroAprobacion:=12345;
   Bloque.AnoAprobacion:=2010;
   Bloque.Serie:='ABC';

   // Asignamos el bloque de folios
   fComprobanteFiscal.BloqueFolios:=Bloque;
   //guardarContenido(fComprobanteFiscal.fXmlComprobante.XML, 'comprobante_fiscal/bloque_folios.xml');
   CheckEquals(sXMLFixture, fComprobanteFiscal.fXmlComprobante.XML,
              'No se guardo el numero de aprobacion, serie y a�o de aprobacion en la estructura del XML');
end;

procedure TestTFEComprobanteFiscal.setBloqueFolios_FolioFueraDeRango_CauseExcepcion;
var
   Bloque: TFEBloqueFolios;
   bHuboError: Boolean;
begin
   Bloque.FolioInicial:=1000;
   Bloque.FolioFinal:=2000;
   bHuboError:=False;

   // Asignamos primero un Numero de Folio fuera del rango
   fComprobanteFiscal.Folio:=Bloque.FolioInicial - 5;

   // Ahora, Asignamos el bloque de folios
   try
      fComprobanteFiscal.BloqueFolios:=Bloque;
   except
      On TFEFolioFueraDeRango do
         bHuboError:=True;
   end;

   CheckEquals(True, bHuboError,
   'No se lanzo la excepcion al asignar un folio fuera del rango especificado en la propiedad BloqueFolios');
end;

procedure TestTFEComprobanteFiscal.setFolio_Folio_LoGuardeEnXML;
var
   sXMLFixture: WideString;
   Folio: TFEFolio;
begin
    // Leemos el contenido de nuestro 'Fixture' para comparar que sean iguales...
   sXMLFixture:=leerContenidoDeFixture('comprobante_fiscal/folio.xml');

   Folio:=12345678;
   fComprobanteFiscal.Folio:=Folio;

   CheckEquals(sXMLFixture, fComprobanteFiscal.fXmlComprobante.XML, 'No se guardo el Folio en la estructura del XML');
end;

procedure TestTFEComprobanteFiscal.Create_NuevoComprobante_GenereEstructuraXMLBasica;
var
   sXMLEncabezadoBasico: WideString;
   NuevoComprobante: TFEComprobanteFiscal;
begin
    // Leemos el contenido de nuestro 'Fixture' para comparar que sean iguales...
   sXMLEncabezadoBasico:=leerContenidoDeFixture('comprobante_fiscal/nuevo.xml');
   NuevoComprobante := TFEComprobanteFiscal.Create;

   // Checamos que sea igual que nuestro Fixture...
   CheckEquals(sXMLEncabezadoBasico, fComprobanteFiscal.fXmlComprobante.XML, 'El encabezado del XML basico para un comprobante no fue el correcto');
   FreeAndNil(NuevoComprobante);
end;

procedure TestTFEComprobanteFiscal.setCertificado_Certificado_GuardeNumeroDeSerieEnEstructuraXML;
var
   Certificado: TFECertificado;
   sXMLConNumSerieCertificado: WideString;
begin
   Certificado.Ruta:=fRutaFixtures + _RUTA_CERTIFICADO;

   // Leemos el contenido de nuestro 'Fixture' para comparar que sean iguales...
   sXMLConNumSerieCertificado:=leerContenidoDeFixture('comprobante_fiscal/numeroserie.xml');

   // Especificamos el certificado que usaremos a la clase comprobante
   fComprobanteFiscal.Certificado:=Certificado;

   // Checamos que sea igual que nuestro Fixture...
   CheckEquals(sXMLConNumSerieCertificado, fComprobanteFiscal.fXmlComprobante.XML, 'El Contenido XML no contiene el numero de serie del certificado o este es incorrecto.');
end;

procedure TestTFEComprobanteFiscal.setEmisor_Emisor_LoGuardeEnXML;
var
  Emisor: TFEContribuyente;
  sXMLConReceptor: WideString;
begin
  Emisor.Nombre:='Industrias del Sur Poniente, S.A. de C.V.';
  Emisor.RFC:='ISP900909Q88';
  with Emisor.Direccion do
  begin
    Calle:='Alvaro Obreg�n';
    NoExterior:='37';
    NoInterior:='';
    CodigoPostal:='31000';
    Colonia:='Col. Roma Norte';
    Municipio:='Cuauht�moc';
    Estado:='Distrito Federal';
    Pais:='M�xico';
    Localidad:='';
    Referencia:='';
  end;

  // Establecemos el receptor
  fComprobanteFiscal.Emisor:=Emisor;

  // Leemos el contenido de nuestro 'Fixture' para comparar que sean iguales...
  sXMLConReceptor:=leerContenidoDeFixture('comprobante_fiscal/emisor.xml');
  CheckEquals(sXMLConReceptor, fComprobanteFiscal.fXmlComprobante.XML, 'El Contenido XML del Comprobante no almaceno correctamente los datos del receptor (es diferente al fixture receptor.xml)');
end;

procedure TestTFEComprobanteFiscal.setReceptor_Receptor_LoGuardeEnXML;
var
  Receptor: TFEContribuyente;
  sXMLConReceptor: WideString;
begin
  Receptor.Nombre:='Rosa Mar�a Calder�n Uriegas';
  Receptor.RFC:='CAUR390312S87';
  with Receptor.Direccion do
  begin
    Calle:='Jardines del Valle';
    NoExterior:='06700';
    NoInterior:='';
    CodigoPostal:='95465';
    Colonia:='Prau Prau';
    Municipio:='Monterrey';
    Estado:='Nuevo Le�n';
    Pais:='M�xico';
    Localidad:='Monterrey';
    Referencia:='';
  end;

  // Establecemos el receptor
  fComprobanteFiscal.Receptor:=Receptor;
  //guardarContenido(fComprobanteFiscal.fXmlComprobante.XML, 'comprobante_fiscal/receptor.xml');
  // Leemos el contenido de nuestro 'Fixture' para comparar que sean iguales...
  sXMLConReceptor:=leerContenidoDeFixture('comprobante_fiscal/receptor.xml');
  CheckEquals(sXMLConReceptor, fComprobanteFiscal.fXmlComprobante.XML, 'El Contenido XML del Comprobante no almaceno correctamente los datos del receptor (es diferente al fixture receptor.xml)');
end;

initialization
  // Registra la prueba de esta unidad en la suite de pruebas
  RegisterTest(TestTFEComprobanteFiscal.Suite);
end.
