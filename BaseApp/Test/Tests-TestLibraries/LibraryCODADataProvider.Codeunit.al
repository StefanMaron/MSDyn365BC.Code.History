codeunit 144016 "Library CODA Data Provider"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;

    [Normal]
    [Scope('OnPrem')]
    procedure ImportMultipleStatementsToCODAstatementDataFiles(FileNo: Integer) fileName: Text
    var
        tempFile: File;
    begin
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        fileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(fileName, TEXTENCODING::Windows);
        if FileNo = 1 then
            // CODA file 07022000.008
            Write7022000008(tempFile)
        else begin
            // CODA file 07022600.005
            Write7022600005A(tempFile);
            Write7022600005B(tempFile);
            Write7022600005C(tempFile);
            Write7022600005D(tempFile);
        end;
        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure ImportAccountTypeTestDataFile() FileName: Text
    var
        tempFile: File;
    begin
        // AL Mapping of the TFS data file 'Fortis 210409.txt
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);

        WriteFortis210409(tempFile);

        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure PrintOneOfMultipleCODAStatementsDataFile() FileName: Text
    var
        tempFile: File;
    begin
        // Implementation of the CODA file CODA1_Multiple.txt
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);
        WriteCODA1MultipleA(tempFile);
        WriteCODA1MultipleB(tempFile);
        WriteCODA1MultipleC(tempFile);
        WriteCODA1MultipleD(tempFile);
        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure OntVangenCODA20090416DataFile() FileName: Text
    var
        tempFile: File;
    begin
        // Implementation of the CODA file Ontvangen CODA.2009-04-16_Original.txt
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);
        WriteOntVangenCODA20090416(tempFile);
        tempFile.Close();
    end;

    [Scope('OnPrem')]
    procedure OntVangenCODAScenario373926DataFile() FileName: Text
    var
        tempFile: File;
    begin
        tempFile.CreateTempFile(TEXTENCODING::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TEXTENCODING::Windows);
        WriteOntVangenCODAScenario373926(tempFile);
        tempFile.Close();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure OnCODAScenario557240DataFile() FileName: Text
    var
        tempFile: File;
    begin
        tempFile.CreateTempFile(TextEncoding::Windows);
        FileName := tempFile.Name;
        tempFile.Close();
        tempFile.TextMode := true;
        tempFile.Create(FileName, TextEncoding::Windows);
        WriteOnCODAScenario557240(tempFile);
        tempFile.Close();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatement(var CODAStatement: Record "CODA Statement"; BankAccountNo: Code[20])
    begin
        CODAStatement.Init();
        CODAStatement."Bank Account No." := BankAccountNo;
        CODAStatement."Statement No." := Format(LibraryRandom.RandInt(210));
        CODAStatement."Statement Ending Balance" := LibraryRandom.RandDecInRange(100000, 200000, 1);
        CODAStatement."Statement Date" := WorkDate();
        CODAStatement."Balance Last Statement" := LibraryRandom.RandDecInRange(10000, 100000, 1);
        CODAStatement."CODA Statement No." := 0;
        CODAStatement.Insert();

        InsertSampleCODAStatementLines(CODAStatement."Statement No.", CODAStatement."Bank Account No.");
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLines(CODAStatementNo: Code[20]; BankAccountNo: Code[20])
    begin
        InsertSampleCODAStatementLine1(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine2(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine3(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine4(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine5(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine6(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine7(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine8(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine9(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine10(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine11(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine12(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine13(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine14(CODAStatementNo, BankAccountNo);
        InsertSampleCODAStatementLine15(CODAStatementNo, BankAccountNo);
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatement(CODAStatement: Record "CODA Statement")
    begin
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 10000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 30000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 40000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 60000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 70000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 80000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 120000);
        ValidateSampleCODAStatementLine(CODAStatement."Statement No.", 130000);
    end;

    local procedure WriteFortis210409(var tempFile: File)
    begin
        tempFile.Write(
          '0000021040920005                  DISTRAC NV                GEBABEBB   00448825928 00000                                       2'
          );
        tempFile.Write('10084230002155541 EUR0BE                  0000000746171930200409' +
          'DISTRAC NV                                                   001');
        tempFile.Write('21000100000000900000404        0000000002689840210409001500000  ' +
          '                                                   21040908401 0');
        tempFile.Write('2300010000210005816416 EUR                     NV F.C.F.        ' +
          '                                                             0 1');
        tempFile.Write('31000100010000900000404        001500001001NV F.C.F.            ' +
          '                                                             1 0');
        tempFile.Write('3200010001STEENWEG OP TIELEN 51              2300 TURNHOUT      ' +
          '                                                             0 0');
        tempFile.Write('21000200000000900000405        100000000005970021040900402000111' +
          '304114376967100031      00476521040916009TOTAL 553121040908401 0');
        tempFile.Write('2200020000      FLEURUS   000000000000000000000000000EUR0611713 ' +
          '                                                             1 0');
        tempFile.Write('2300020000                                     TOTAL 5531      F' +
          'LEURUS            00976                                      0 1');
        tempFile.Write('31000200010000900000405        004020001001TOTAL 5531      FLEUR' +
          'US                                                           1 0');
        tempFile.Write('3200020001                                   0000               ' +
          '                                                             0 0');
        tempFile.Write('8084230002155541 EUR0BE                  0000000748802070210409 ' +
          '                                                               0');
        tempFile.Write('9               000011000000000059700000000002689840            ' +
          '                                                               1');
    end;

    local procedure Write7022000008(var tempFile: File)
    begin
        // CODA file 07022000.008
        tempFile.Write('0000019020772505   0000000074789  THIELEMANS ROBBIE         0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 032737010689443 EUR0BE                  0000000236074080140207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000BJUA00109 TBOINDNLOON1000000001352480190207001010000ON' +
          'KOSTEN BELCOMP EN VDVIJVER                         1902070320100');
        tempFile.Write('2200010000                                                     D' +
          'IV ONKO                     000000000000000                  100');
        tempFile.Write('2300010000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('8032737010689443 EUR0BE                  0000000234721600190207 ' +
          '                                                                ');
        tempFile.Write('9               000005000000001352480000000000000000            ' +
          '                                                               2');
    end;

    local procedure Write7022600005A(var tempFile: File)
    begin
        tempFile.Write('0000002010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 001737010689443 EUR0BE                  0000000291493520291206' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000HIRQA1H6L BKTKOSKOKFG1000000000020000010107303370000Aa' +
          'nrekening kaartbijdrage   5526 1454 7849 0607      0201070011000');
        tempFile.Write('2100010001HIRQA1H6L BKTKOSKOKFG1000000000020000010107803370060  ' +
          '                                                   0201070011000');
        tempFile.Write('2100020000HIWC00001 CKZKOSKOSBK1000000000018700020107013370000  ' +
          '  COMMERCIELE KREDIETZAAK MET REFERTE      727-64440201070010100');
        tempFile.Write('2200020000961-49                                                ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9426419JBBOEUBCRECL000000000799200003010734150000000' +
          '352037002A3545                                     0201070011100');
        tempFile.Write('2200030000                                                     4' +
          '550-63629896326             000000000000000                  001');
        tempFile.Write('3100030001OL9426419JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320003000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9426419JBBOEUBCRECL341500001002INVOIC               ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9426419JBBOEUBCRECL000000000799200003010784150100110' +
          '5000000007992000000000007992000000100000000EUR     0201070011100');
        tempFile.Write('2200030003         000000007992000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000HNOA00002BTBOGOVOVERS000000000151250002010700150000062' +
          '91                                                 0201070010100');
        tempFile.Write('2300040000472302320181                         TEAM LASERPRESS N' +
          'V        JACQUES PARYSLAAN 8       9940 EVERGEM              000');
        tempFile.Write('2100050000HOUP00283BTBOINDNLOON0000000001024930020107001500000FT' +
          ' 6314                                              0201070010100');
        tempFile.Write('2300050000738010356689                         EVILO NV         ' +
          '         SCHELDESTRAAT 35 A        8553 OTEGEM               000');
        tempFile.Write('2100060000OL9447899JBBNEUBCRCL1000000003378098003010734150000000' +
          '352037002C0877                                     0201070011001');
        tempFile.Write('3100060001OL9447899JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              3110001                                        1 0');
        tempFile.Write('320006000129                                                    ' +
          '                                                             0 1');
        tempFile.Write('3100060002OL9447899JBBNEUBCRCL1341500001002INV 6320             ' +
          '                                                             0 0');
        tempFile.Write('2100060003OL9447899JBBNEUBCRCL1000000003378098003010784150100110' +
          '5000000033780980000000033780980000100000000EUR     0201070011100');
        tempFile.Write('2200060003         000000033780980                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8001737010689443 EUR0BE                  0000000335765230020107 ' +
          '                                                                ');
        tempFile.Write('9               000023000000000038700000000044310410            ' +
          '                                                               1');
        tempFile.Write('0000003010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 002737010689443 EUR0BE                  0000000335765230020107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9460983JBBOEUBCRECL000000002220652004010734150000000' +
          '352037003A7683                                     0301070021100');
        tempFile.Write('2200010000                                                     T' +
          '47A70102AU78                000000000000000                  001');
        tempFile.Write('3100010001OL9460983JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200010001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9460983JBBOEUBCRECL341500001002INV. 6318 / 30.11.200' +
          '6             INV. 6315 / 24.11.2006                         1 0');
        tempFile.Write('3200010002./. BELASTUNG 17004039 / 19.12.2006                   ' +
          '                                                             0 0');
        tempFile.Write('2100010003OL9460983JBBOEUBCRECL000000002220652004010784150100110' +
          '5000000022206520000000022206520000100000000EUR     0301070021100');
        tempFile.Write('2200010003         000000022206520                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8002737010689443 EUR0BE                  0000000357971750030107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000022206520            ' +
          '                                                               1');
        tempFile.Write('0000005010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 003737010689443 EUR0BE                  0000000357971750040107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JCRL02237 TBOINDNLOON1000000013310000050107001010000FA' +
          'CT ST06012                                         0501070030100');
        tempFile.Write('2200010000                                                     6' +
          '/1900                       000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('8003737010689443 EUR0BE                  0000000344661750050107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000013310000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000008010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 004737010689443 EUR0BE                  0000000344661750050107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JQQJA0CUQ IKLINNINNIG1000000003670020060107313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0801070041000');
        tempFile.Write('2100010001JQQJA0CUQ IKLINNINNIG1000000003333330060107813410660  ' +
          '                                                   0801070040000');
        tempFile.Write('2100010002JQQJA0CUQ IKLINNINNIG1000000000336690060107813410020  ' +
          '                                                   0801070041000');
        tempFile.Write('2100020000OL9441847JBBNEUNCRCL1000000005292465008010734150000000' +
          '352037008A2593                                     0801070041001');
        tempFile.Write('3100020001OL9441847JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9441847JBBNEUNCRCL13415000010026710280720000130 6306' +
          ' 6309 6311                                                   0 0');
        tempFile.Write('2100020003OL9441847JBBNEUNCRCL1000000005292465008010784150100110' +
          '5000000052924650000000052924650000100000000EUR     0801070041100');
        tempFile.Write('2200020003         000000052924650                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9441848KBBNKOSDIVKS100000000001089008010734137000000' +
          '352037008A2593                                     0801070041000');
        tempFile.Write('2100030001OL9441848KBBNKOSDIVKS1000000000009000080107841370130  ' +
          '                                                   0801070040000');
        tempFile.Write('2100030002OL9441848KBBNKOSDIVKS100000000000189008010784137011110' +
          '6000000000001890000000000009000002100000000200000000801070041100');
        tempFile.Write('220003000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000KBIS00253 TBOINDNLOON100000000304899008010700101000110' +
          '1006000522050                                      0801070040100');
        tempFile.Write('2200040000                                                     6' +
          '1823                        000000000000000                  100');
        tempFile.Write('2300040000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100050000KBIS00254 TBOINDNLOON100000000001479008010700101000110' +
          '1006000523969                                      0801070040100');
        tempFile.Write('2200050000                                                     6' +
          '1867                        000000000000000                  100');
        tempFile.Write('2300050000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100060000KBIS00255 TBOINDNLOON100000000360973008010700101000110' +
          '1007000047537                                      0801070040100');
        tempFile.Write('2200060000                                                     6' +
          '/1941                       000000000000000                  100');
        tempFile.Write('2300060000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('8004737010689443 EUR0BE                  0000000387231980080107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000010354420000000052924650            ' +
          '                                                               1');
        tempFile.Write('0000009010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 005737010689443 EUR0BE                  0000000387231980080107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KFXWA0BSQ IKLINNINNIG1000000000991820090107313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0901070051000');
        tempFile.Write('2100010001KFXWA0BSQ IKLINNINNIG1000000000947310090107813410660  ' +
          '                                                   0901070050000');
        tempFile.Write('2100010002KFXWA0BSQ IKLINNINNIG1000000000044510090107813410020  ' +
          '                                                   0901070051000');
        tempFile.Write('2100020000KGNAA0ANJ DOMALGDOV01100000000070164009010700501000110' +
          '774071599264509010774422-LF-0  2532992   413664   00901070050100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000KHMC01793 TBOINDNLOON1000000000553560090107001010000IN' +
          'V 7006237 RI KLNR 92164                            0901070050100');
        tempFile.Write('2200030000                                                     6' +
          '1695                        000000000000000                  100');
        tempFile.Write('2300030000437751551186                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100040000KHMC01794 TBOINDNLOON1000000000209570090107001010000FA' +
          'CT2070004583                                       0901070050100');
        tempFile.Write('2200040000                                                     6' +
          '1744                        000000000000000                  100');
        tempFile.Write('2300040000390041400059                         AIR COMPACT BELGI' +
          'UM NV    BRUSSelseSTWG 427         9050 LEDEBERG (GENT       000');
        tempFile.Write('2100050000KHMC01795 TBOINDNLOON100000000011173009010700101000009' +
          '0059 2000 06006310                                 0901070050100');
        tempFile.Write('2200050000                                                     6' +
          '/1575                       000000000000000                  100');
        tempFile.Write('2300050000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100060000KHMC01796 TBOINDNLOON100000000010682009010700101000009' +
          '0059 2000 06006658                                 0901070050100');
        tempFile.Write('2200060000                                                     6' +
          '/1615                       000000000000000                  100');
        tempFile.Write('2300060000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100070000KHMC01797 TBOINDNLOON100000000015277009010700101000110' +
          '1200601108664                                      0901070050100');
        tempFile.Write('2200070000                                                     6' +
          '1668                        000000000000000                  100');
        tempFile.Write('2300070000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100080000KHMC01798 TBOINDNLOON100000000032818009010700101000110' +
          '1200601236986                                      0901070050100');
        tempFile.Write('2200080000                                                     6' +
          '1798                        000000000000000                  100');
        tempFile.Write('2300080000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100090000KHMC01799 TBOINDNLOON100000000008494009010700101000110' +
          '1200641227460                                      0901070050100');
        tempFile.Write('2200090000                                                     6' +
          '1804                        000000000000000                  100');
        tempFile.Write('2300090000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100100000KHMC01800 TBOINDNLOON100000000017015009010700101000110' +
          '1200601285284                                      0901070050100');
        tempFile.Write('2200100000                                                     6' +
          '1813                        000000000000000                  100');
        tempFile.Write('2300100000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100110000KHMC01801 TBOINDNLOON1000000000512740090107001010000FA' +
          'CT 28016149 S01 028                                0901070050100');
        tempFile.Write('2200110000                                                     6' +
          '1592                        000000000000000                  100');
        tempFile.Write('2300110000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100120000KHMC01802 TBOINDNLOON1000000000902630090107001010000FT' +
          '111602572 602741 602867 602892 602981 603069 6030720901070050100');
        tempFile.Write('2200120000                                                     6' +
          '1607829                     000000000000000                  100');
        tempFile.Write('2300120000447964515175                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100130000KHMC01803 TBOINDNLOON100000000076807009010700101000110' +
          '1009005562044                                      0901070050100');
        tempFile.Write('2200130000                                                     6' +
          '1671                        000000000000000                  100');
        tempFile.Write('2300130000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100140000KHMC01804 TBOINDNLOON100000000076807009010700101000110' +
          '1009005671875                                      0901070050100');
        tempFile.Write('2200140000                                                     6' +
          '1874                        000000000000000                  100');
        tempFile.Write('2300140000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100150000KHMC01805 TBOINDNLOON1000000010619930090107001010000IN' +
          'V164091 164092 164170 164168 164169 164184         0901070050100');
        tempFile.Write('2200150000                                                     6' +
          '1704712                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000KHMC01806 TBOINDNLOON1000000005455890090107001010000IN' +
          'V 06111601 111602 111603                           0901070050100');
        tempFile.Write('2200160000                                                     6' +
          '168789                      000000000000000                  100');
        tempFile.Write('2300160000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100170000KHMC01807 TBOINDNLOON1000000000135680090107001010000BR' +
          'U0905683                                           0901070050100');
        tempFile.Write('2200170000                                                     6' +
          '1779                        000000000000000                  100');
        tempFile.Write('2300170000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100180000KHMC01808 TBOINDNLOON1000000000732900090107001010000IN' +
          'V122810 KLANT822346                                0901070050100');
        tempFile.Write('2200180000                                                     6' +
          '1667                        000000000000000                  100');
        tempFile.Write('2300180000825601419034                         EBV              ' +
          '         EXCELSIORLN 68            1930 ZAVENTEM             000');
        tempFile.Write('2100190000KHMC01809 TBOINDNLOON1000000000961950090107001010000IN' +
          'V 712559 717757 720476                             0901070050100');
        tempFile.Write('2200190000                                                     6' +
          '1731885                     000000000000000                  100');
        tempFile.Write('2300190000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100200000KHMC01810 TBOINDNLOON1000000002447810090107001010000FA' +
          'CT504658                                           0901070050100');
        tempFile.Write('2200200000                                                     6' +
          '1727                        000000000000000                  100');
        tempFile.Write('2300200000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100210000KHMC01811 TBOINDNLOON1000000000467990090107001010000IN' +
          'V96133105 TO96142988                               0901070050100');
        tempFile.Write('2200210000                                                     6' +
          '149991                      000000000000000                  100');
        tempFile.Write('2300210000733031146932                         FABORY           ' +
          '         ZWEDENSTRAAT 4            9940 EVERGEM              000');
        tempFile.Write('2100220000KHMC01812 TBOINDNLOON100000000007132009010700101000110' +
          '1162033288470                                      0901070050100');
        tempFile.Write('2200220000                                                     6' +
          '1854                        000000000000000                  100');
        tempFile.Write('2300220000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100230000KHMC01813 TBOINDNLOON1000000001408000090107001010000IN' +
          'V841175 853828                                     0901070050100');
        tempFile.Write('2200230000                                                     6' +
          '176449                      000000000000000                  100');
        tempFile.Write('2300230000720520635687                         FUTURE ELECTRONIC' +
          'S        BRANDSTR 15A              9160 LOKEREN              000');
        tempFile.Write('2100240000KHMC01814 TBOINDNLOON1000000001275340090107001010000IN' +
          'V108687                                            0901070050100');
        tempFile.Write('2200240000                                                     6' +
          '1683                        000000000000000                  100');
        tempFile.Write('2300240000410065152192                         GIVATEC          ' +
          '         INDUSTRIEWEG 5            3001 HEVERLEE             000');
        tempFile.Write('2100250000KHMC01815 TBOINDNLOON1000000000045190090107001010000FA' +
          'CT94886                                            0901070050100');
        tempFile.Write('2200250000                                                     6' +
          '1769                        000000000000000                  100');
        tempFile.Write('2300250000335043322468                         IMES OOST VLAANDE' +
          'REN      KORTE MAGERSTRAAT 3       9050 GENTBRUGGE           000');
        tempFile.Write('2100260000KHMC01816 TBOINDNLOON1000000001830000090107001010000IN' +
          'V191537                                            0901070050100');
        tempFile.Write('2200260000                                                     6' +
          '1526                        000000000000000                  100');
        tempFile.Write('2300260000340182596777                         LEM INSTRUMENTS  ' +
          '                                   1000 BRUSSEL 1            000');
        tempFile.Write('2100270000KHMC01817 TBOINDNLOON100000000017302009010700101000110' +
          '1206193754509                                      0901070050100');
        tempFile.Write('2200270000                                                     6' +
          '1776                        000000000000000                  100');
        tempFile.Write('2300270000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100280000KHMC01818 TBOINDNLOON1000000000832470090107001010000IN' +
          'V4082537                                           0901070050100');
        tempFile.Write('2200280000                                                     6' +
          '1662                        000000000000000                  100');
        tempFile.Write('2300280000552270880026                         MISCO            ' +
          '         POSTBUS 156               1930 ZAVENTEM             000');
        tempFile.Write('2100290000KHMC01819 TBOINDNLOON1000000000457380090107001010000IN' +
          'V VG062501107                                      0901070050100');
        tempFile.Write('2200290000                                                     6' +
          '1654                        000000000000000                  100');
        tempFile.Write('2300290000414520300154                         NIJKERK ELECTRONI' +
          'CS       NOORDERLAAN 111           2030 ANTWERPEN 3          000');
        tempFile.Write('2100300000KHMC01820 TBOINDNLOON1000000000146170090107001010000IN' +
          'VOICE 60107183RI CUSTOMER 42103297                 0901070050100');
        tempFile.Write('2200300000                                                     6' +
          '1738                        000000000000000                  100');
        tempFile.Write('2300300000432401944101                         OMRON            ' +
          '         STATIONSSTRAAT 24         1702 GROOT-BIJGAARD       000');
        tempFile.Write('2100310000KHMC01821 TBOINDNLOON1000000000572330090107001010000IN' +
          'V23807                                             0901070050100');
        tempFile.Write('2200310000                                                     6' +
          '1835                        000000000000000                  100');
        tempFile.Write('2300310000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100320000KHMC01822 TBOINDNLOON1000000000223730090107001010000IN' +
          'V61331 60554                                       0901070050100');
        tempFile.Write('2200320000                                                     6' +
          '164882                      000000000000000                  100');
        tempFile.Write('2300320000437750008179                         PHOENIX CONTACT  ' +
          '         MINERVASTRAAT 10-12       1930 ZAVENTEM             000');
        tempFile.Write('2100330000KHMC01823 TBOINDNLOON100000000640961009010700101000110' +
          '1060680430143                                      0901070050100');
        tempFile.Write('2200330000                                                     6' +
          '1834                        000000000000000                  100');
        tempFile.Write('2300330000001446507648                         RANDSTAD PROF    ' +
          '         HEIZEL ESPLANADE          1020 BRUSSEL 2            000');
        tempFile.Write('2100340000KHMC01824 TBOINDNLOON1000000001053590090107001010000IN' +
          'V6299051                                           0901070050100');
        tempFile.Write('2200340000                                                     6' +
          '1773                        000000000000000                  100');
        tempFile.Write('2300340000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUSSEL              000');
        tempFile.Write('2100350000KHMC01825 TBOINDNLOON1000000000533320090107001010000IN' +
          'V553060 557754                                     0901070050100');
        tempFile.Write('2200350000                                                     6' +
          '169465                      000000000000000                  100');
        tempFile.Write('2300350000310161043025                         RS COMPONENTS    ' +
          '         BD PAEPSEMLAAN 22         1070 ANDERLECHT           000');
        tempFile.Write('2100360000KHMC01826 TBOINDNLOON1000000006014750090107001010000IN' +
          'V4495806 TO4555463                                 0901070050100');
        tempFile.Write('2200360000                                                     6' +
          '150491                      000000000000000                  100');
        tempFile.Write('2300360000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100370000KHMC01827 TBOINDNLOON1000000002420000090107001010000IN' +
          'V50780                                             0901070050100');
        tempFile.Write('2200370000                                                     6' +
          '1801                        000000000000000                  100');
        tempFile.Write('2300370000430084575196                         SEHER            ' +
          '         ASSESTEENWEG 117 2        1740 TERNAT               000');
        tempFile.Write('2100380000KHMC01828 TBOINDNLOON1000000000470090090107001010000IN' +
          'V9166859                                           0901070050100');
        tempFile.Write('2200380000                                                     6' +
          '1642                        000000000000000                  100');
        tempFile.Write('2300380000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100390000KHMC01829 TBOINDNLOON100000000048822009010700101000110' +
          '1630311096035                                      0901070050100');
        tempFile.Write('2200390000                                                     6' +
          '1752                        000000000000000                  100');
        tempFile.Write('2300390000407050860119                         STANDAARD BOEKHAN' +
          'DEL      INDUSTRIEPARK NOORD 28A   9100 ST-NIKLAAS           000');
        tempFile.Write('2100400000KHMC01830 TBOINDNLOON1000000001064250090107001010000IN' +
          'V10052583 10052504 10052509                        0901070050100');
        tempFile.Write('2200400000                                                     6' +
          '1780 82                     000000000000000                  100');
        tempFile.Write('2300400000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100410000KHMC01831 TBOINDNLOON1000000000715970090107001010000DI' +
          'V INV                                              0901070050100');
        tempFile.Write('2200410000                                                     6' +
          '1899                        000000000000000                  100');
        tempFile.Write('2300410000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100420000KHMC01832 TBOINDNLOON1000000000380000090107001010000IN' +
          'V80274362                                          0901070050100');
        tempFile.Write('2200420000                                                     6' +
          '1736                        000000000000000                  100');
        tempFile.Write('2300420000720540560602                         TYCO EL          ' +
          '                                                             000');
        tempFile.Write('2100430000KHMC01833 TBOINDNLOON1000000000323740090107001010000IN' +
          'V611791 KLANT 4268                                 0901070050100');
        tempFile.Write('2200430000                                                     6' +
          '1777                        000000000000000                  100');
        tempFile.Write('2300430000068241941669                         VANSICHEN        ' +
          '         BREDEWEG 62               3723 KORTESSEM            000');
        tempFile.Write('2100440000KHMC01834 TBOINDNLOON1000000000527620090107001010000IN' +
          'V601717                                            0901070050100');
        tempFile.Write('2200440000                                                     6' +
          '1698                        000000000000000                  100');
        tempFile.Write('2300440000446064891124                         VANDEVYVER       ' +
          '         BENELUXLN 1               9060 ZELZATE              000');
        tempFile.Write('2100450000KHMC01835 TBOINDNLOON1000000000024200090107001010000FA' +
          'CT602844 8612                                      0901070050100');
        tempFile.Write('2200450000                                                     6' +
          '1665                        000000000000000                  100');
        tempFile.Write('2300450000645141021968                         VENTOMATIC       ' +
          '         CHRYSANTENSTRAAT 59B      9820 MERELBEKE            000');
        tempFile.Write('2100460000KHMC01836 TBOINDNLOON1000000004416500090107001010000IN' +
          'V606087                                            0901070050100');
        tempFile.Write('2200460000                                                     6' +
          '1845                        000000000000000                  100');
        tempFile.Write('2300460000443563835141                         VANSTEENBRUGGHE N' +
          'V        BERCHEMWEG 95             9700 OUDENAARDE           000');
        tempFile.Write('2100470000KHMC01837 TBOINDNLOON1000000001698840090107001010000IN' +
          'V223602                                            0901070050100');
        tempFile.Write('2200470000                                                     6' +
          '1750                        000000000000000                  100');
        tempFile.Write('2300470000891374071719                         WYNANT           ' +
          '         AALSTSTRAAT 28            9700 OUDENAARDE           000');
        tempFile.Write('2100480000OL9470740IUBOEUBTRFCS100000000059200008010734101000000' +
          '352037009A1848                                     0901070051100');
        tempFile.Write('2200480000                                                     6' +
          '1802                        000000000000000                  001');
        tempFile.Write('3100480001OL9470740IUBOEUBTRFCS341010001001AMECHA BV            ' +
          '              GRASBEEMD 15A                                  1 0');
        tempFile.Write('32004800015705 DE HELMOND NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100480002OL9470740IUBOEUBTRFCS341010001002FACT06223            ' +
          '                                                             0 1');
        tempFile.Write('3100480003OL9470740IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100480004OL9470740IUBOEUBTRFCS100000000059200008010784101100110' +
          '5000000000592000000000000592000000100000000EUR     0901070051100');
        tempFile.Write('2200480004         000000000592000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100490000OL9470741IUBOEUBTRFCS100000000065000008010734101000000' +
          '352037009A1849                                     0901070051100');
        tempFile.Write('2200490000                                                     6' +
          '1864 65                     000000000000000                  001');
        tempFile.Write('3100490001OL9470741IUBOEUBTRFCS341010001001BALKHAUSEN           ' +
          '              RUDOLF DIESEL STR 17                           1 0');
        tempFile.Write('320049000128857 SYKE DE                      DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100490002OL9470741IUBOEUBTRFCS341010001002INVOICE 0703023      ' +
          '              0703024                                        0 1');
        tempFile.Write('3100490003OL9470741IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100490004OL9470741IUBOEUBTRFCS100000000065000008010784101100110' +
          '5000000000650000000000000650000000100000000EUR     0901070051100');
        tempFile.Write('2200490004         000000000650000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100500000OL9470742IUBOEUBTRFCS100000000002690008010734101000000' +
          '352037009A1850                                     0901070051100');
        tempFile.Write('2200500000                                                     6' +
          '1841                        000000000000000                  001');
        tempFile.Write('3100500001OL9470742IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320050000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
    end;

    local procedure Write7022600005B(var tempFile: File)
    begin
        tempFile.Write('3100500002OL9470742IUBOEUBTRFCS341010001002INV93750             ' +
          '                                                             0 1');
        tempFile.Write('3100500003OL9470742IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100500004OL9470742IUBOEUBTRFCS100000000002690008010784101100110' +
          '5000000000026900000000000026900000100000000EUR     0901070051100');
        tempFile.Write('2200500004         000000000026900                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100510000OL9470743IUBOEUBTRFCS100000000033000008010734101000000' +
          '352037009A1851                                     0901070051100');
        tempFile.Write('2200510000                                                     6' +
          '1713                        000000000000000                  001');
        tempFile.Write('3100510001OL9470743IUBOEUBTRFCS341010001001KEMA QUALITY BV      ' +
          '              UTRECHTSESTEENWEG 310                          1 0');
        tempFile.Write('32005100016812AR ARNHEM NL                   NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100510002OL9470743IUBOEUBTRFCS34101000100217268 2188747        ' +
          '                                                             0 1');
        tempFile.Write('3100510003OL9470743IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100510004OL9470743IUBOEUBTRFCS100000000033000008010784101100110' +
          '5000000000330000000000000330000000100000000EUR     0901070051100');
        tempFile.Write('2200510004         000000000330000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100520000OL9470744IUBOEUBTRFCS100000000026095008010734101000000' +
          '352037009A1857                                     0901070051100');
        tempFile.Write('2200520000                                                     6' +
          '1739                        000000000000000                  001');
        tempFile.Write('3100520001OL9470744IUBOEUBTRFCS341010001001TTI INC              ' +
          '              GANGHOFERSTRASSE 34                            1 0');
        tempFile.Write('320052000182216 MAISACH-GERNLINDEN DE        DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100520002OL9470744IUBOEUBTRFCS341010001002INV E00888030        ' +
          '                                                             0 1');
        tempFile.Write('3100520003OL9470744IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100520004OL9470744IUBOEUBTRFCS100000000026095008010784101100110' +
          '5000000000260950000000000260950000100000000EUR     0901070051100');
        tempFile.Write('2200520004         000000000260950                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100530000OL9470745IUBOEUBTRFCS100000000272921008010734101000000' +
          '352037009A1858                                     0901070051100');
        tempFile.Write('2200530000                                                     6' +
          '1692 1719 1853              000000000000000                  001');
        tempFile.Write('3100530001OL9470745IUBOEUBTRFCS341010001001VERMEULEN PRINTSSERVI' +
          'CE            HELMONDSEWEG 7B                                1 0');
        tempFile.Write('32005300015735 RA AARLE-RIXTEL NL            NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100530002OL9470745IUBOEUBTRFCS341010001002INV IO6 07298 07     ' +
          '              430                                            0 1');
        tempFile.Write('3100530003OL9470745IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100530004OL9470745IUBOEUBTRFCS100000000272921008010784101100110' +
          '5000000002729210000000002729210000100000000EUR     0901070051100');
        tempFile.Write('2200530004         000000002729210                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100540000OL9470746IUBOEUBTRFCS100000000037500008010734101000000' +
          '352037009A1852                                     0901070051100');
        tempFile.Write('2200540000                                                     6' +
          '1728                        000000000000000                  001');
        tempFile.Write('3100540001OL9470746IUBOEUBTRFCS341010001001KONING EN HARTMAN BV ' +
          '              POSTBUS 416                                    1 0');
        tempFile.Write('32005400011000AK AMSTERDAM NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100540002OL9470746IUBOEUBTRFCS341010001002INV5100052503        ' +
          '                                                             0 1');
        tempFile.Write('3100540003OL9470746IUBOEUBTRFCS341010001004VAN LANSCHOT F BANKIE' +
          'RS NV                                                        0 0');
        tempFile.Write('2100540004OL9470746IUBOEUBTRFCS100000000037500008010784101100110' +
          '5000000000375000000000000375000000100000000EUR     0901070051100');
        tempFile.Write('2200540004         000000000375000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100550000OL9470747IUBOEUBTRFCS100000000173224008010734101000000' +
          '352037009A1853                                     0901070051100');
        tempFile.Write('2200550000                                                     6' +
          '1882                        000000000000000                  001');
        tempFile.Write('3100550001OL9470747IUBOEUBTRFCS341010001001PHILIPS OVAR         ' +
          '              EN109/IC1 ZONA IND OVAR                        1 0');
        tempFile.Write('32005500013880728 OVAR PT                    PT                 ' +
          '                                                             0 1');
        tempFile.Write('3100550002OL9470747IUBOEUBTRFCS341010001002INV789179            ' +
          '                                                             0 1');
        tempFile.Write('3100550003OL9470747IUBOEUBTRFCS341010001004BANCO BILBAO VIZCAYA ' +
          'ARGENTARIA (PO                                               0 0');
        tempFile.Write('2100550004OL9470747IUBOEUBTRFCS100000000173224008010784101100110' +
          '5000000001732240000000001732240000100000000EUR     0901070051100');
        tempFile.Write('2200550004         000000001732240                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100560000OL9470749IUBOEUBTRFCS100000000362410008010734101000000' +
          '352037009A1854                                     0901070051100');
        tempFile.Write('2200560000                                                     6' +
          '169647                      000000000000000                  001');
        tempFile.Write('3100560001OL9470749IUBOEUBTRFCS341010001001PIHER                ' +
          '              AMBACHTSSTR 13B                                1 0');
        tempFile.Write('32005600013861 HR NIJKERK NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100560002OL9470749IUBOEUBTRFCS341010001002INV110640 110692     ' +
          '                                                             0 1');
        tempFile.Write('3100560003OL9470749IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100560004OL9470749IUBOEUBTRFCS100000000362410008010784101100110' +
          '5000000003624100000000003624100000100000000EUR     0901070051100');
        tempFile.Write('2200560004         000000003624100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100570000OL9470750IUBOEUBTRFCS100000000025001008010734101000000' +
          '352037009A1856                                     0901070051100');
        tempFile.Write('2200570000                                                     6' +
          '1814                        000000000000000                  001');
        tempFile.Write('3100570001OL9470750IUBOEUBTRFCS341010001001BV SNIJ-UNIE HIFI    ' +
          '              ZOUTKETEN 23                                   1 0');
        tempFile.Write('32005700011601EX ENKHUIZEN NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100570002OL9470750IUBOEUBTRFCS341010001002INV267116 KLANT2     ' +
          '              136                                            0 1');
        tempFile.Write('3100570003OL9470750IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100570004OL9470750IUBOEUBTRFCS100000000025001008010784101100110' +
          '5000000000250010000000000250010000100000000EUR     0901070051100');
        tempFile.Write('2200570004         000000000250010                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100580000OL9470751IUBOEUNTRFCS100000001604164008010734101000000' +
          '352037009A1855                                     0901070051001');
        tempFile.Write('3100580001OL9470751IUBOEUNTRFCS341010001001PUNCH TECHNIX NV     ' +
          '              KROMMESPIERINGWEG 289B                         1 0');
        tempFile.Write('32005800012141BS VIJFHUIZEN NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100580002OL9470751IUBOEUNTRFCS341010001002INV204700680         ' +
          '              FACTUUR204700252 PUNCH TECHNIX NV              0 1');
        tempFile.Write('3100580003OL9470751IUBOEUNTRFCS341010001004BANQUE ARTESIA NEDERL' +
          'AND                                                          0 0');
        tempFile.Write('2100580004OL9470751IUBOEUNTRFCS100000001604164008010784101100110' +
          '5000000016041640000000016041640000100000000EUR     0901070051100');
        tempFile.Write('2200580004         000000016041640                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100590000OL9470752KUBOKOSDIVKS100000000001210008010734137000000' +
          '352037009A1855                                     0901070051000');
        tempFile.Write('2100590001OL9470752KUBOKOSDIVKS1000000000010000080107841370260  ' +
          '                                                   0901070050000');
        tempFile.Write('2100590002OL9470752KUBOKOSDIVKS100000000000210008010784137011110' +
          '6000000000002100000000000010000002100000000200000000901070051100');
        tempFile.Write('220059000200002100                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100600000KJXV14365BOVSBBNONTVA000000000061147009010700150000062' +
          '90                                                 0901070050100');
        tempFile.Write('220060000010/062-260985                                         ' +
          '                            000000000000000                  100');
        tempFile.Write('2300600000260035911186                         GO TO SA         ' +
          '         CHEMIN DE HAMEAU 25       6120    HAM-SUR-HEURE     000');
        tempFile.Write('21006100007409A3A5G KGDTTNTERNG1000000008000000080107009010000  ' +
          '                                                   0901070050000');
        tempFile.Write('8005737010689443 EUR0BE                  0000000292458810090107 ' +
          '                                                                ');
        tempFile.Write('9               000238000000095384640000000000611470            ' +
          '                                                               1');
        tempFile.Write('0000010010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 006737010689443 EUR0BE                  0000000292458810090107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KTTEA0CTR DOMALGDOV01100000000105784010010700501000110' +
          '7740784372894100107I=0701599551 R=36291539        01001070060100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000LEGLA0B5R DOMNINDIN01100000007880763010010700501000110' +
          '7740784719367110107      060534695                01001070060100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8006737010689443 EUR0BE                  0000000212593340100107 ' +
          '                                                                ');
        tempFile.Write('9               000008000000079865470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000011010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 007737010689443 EUR0BE                  0000000212593340100107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000LJEHA0APR DOMALGDOV01100000000028146011010700501000110' +
          '774071599264511010773518-LF-0  2536630   413794   01101070070100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000LJEHA0APS DOMALGDOV01100000000028702011010700501000110' +
          '774071599264511010773520-LF-0  2536631   413794   01101070070100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000LJEHA0APT DOMALGDOV01100000000033999011010700501000110' +
          '774071599264511010773521-LF-0  2536632   413794   01101070070100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('8007737010689443 EUR0BE                  0000000211684870110107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000000908470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000012010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 008737010689443 EUR0BE                  0000000211684870110107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9464620JBBNEUBCRCL1000000002898250012010734150000000' +
          '352037012A3186                                     1201070081001');
        tempFile.Write('3100010001OL9464620JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9464620JBBNEUBCRCL13415000010026710280720000227 6324' +
          ' 6326                                                        0 0');
        tempFile.Write('2100010003OL9464620JBBNEUBCRCL1000000002898250012010784150100110' +
          '5000000028982500000000028982500000100000000EUR     1201070081100');
        tempFile.Write('2200010003         000000028982500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000MGLC00104BTBOGOVOVERS0000000000112530120107001500000  ' +
          '          6303                                     1201070080100');
        tempFile.Write('2300020000443900062197                         SANTENS NV       ' +
          '         GALGESTRAAT 157           9700 OUDENAARDE           000');
        tempFile.Write('8008737010689443 EUR0BE                  0000000240779900120107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000029095030            ' +
          '                                                               1');
        tempFile.Write('0000015010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 009737010689443 EUR0BE                  0000000240779900120107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000MLMPA0AMU DOMALGDOV01100000000028712015010700501000110' +
          '774071599264515010778359-LF-0  2540014   413946   01501070090100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000MUUB02943LKKTOVSOVKUG100000000347147015010700319000112' +
          '45526145478490607    1431                          1501070090100');
        tempFile.Write('2300020000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8009737010689443 EUR0BE                  0000000237021310150107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000003758590000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 010737010689443 EUR0BE                  0000000237021310150107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NAIAA0AA0 DOMNINDIN01100000000001084016010700501000110' +
          '7740784719367170107      070031236                01601070100100');
        tempFile.Write('22000100000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100020000NKGU00273 TBOINDNLOON1000000000020010160107001010000EX' +
          'P TANKEN                                           1601070100100');
        tempFile.Write('2200020000                                                     D' +
          'IV6117                      000000000000000                  100');
        tempFile.Write('2300020000001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100030000NKGU00274 TBOINDNLOON1000000000136250160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200030000                                                     D' +
          'IV6118                      000000000000000                  100');
        tempFile.Write('2300030000737101218432                         VAN DE SYPE DAVID' +
          '         STATIONSSTR 124           9450 HAALTERT             000');
        tempFile.Write('2100040000NKGU00275 TBOINDNLOON1000000000092920160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200040000                                                     D' +
          'IV6119                      000000000000000                  100');
        tempFile.Write('2300040000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100050000NKGU00276 TBOINDNLOON1000000000093500160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200050000                                                     D' +
          'IV6120                      000000000000000                  100');
        tempFile.Write('2300050000733163053996                         VERMEER PAUL     ' +
          '         TEN OTTER 80              2980 ZOERSEL              000');
        tempFile.Write('2100060000NKGU00277 TBOINDNLOON1000000000116800160107001010000EX' +
          'P JAN07                                            1601070100100');
        tempFile.Write('2200060000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300060000737005116185                         ISABELLE VAN DER ' +
          'PLAETSEN VARENDRIESKOUTER 4        9031 DRONGEN              000');
        tempFile.Write('8010737010689443 EUR0BE                  0000000236550990160107 ' +
          '                                                                ');
        tempFile.Write('9               000020000000000470320000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000017010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 011737010689443 EUR0BE                  0000000236550990160107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NOEOA0BUR DOMDCDDID01100000000002804017010700501000110' +
          '7740745036768180107F. 2007040813 DOMICIL.         01701070110100');
        tempFile.Write('22000100000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('2100020000NRGD00175 TBOINDNLOON1000000004537500170107001010000FA' +
          'CT 27019                                           1701070110100');
        tempFile.Write('2200020000                                                     6' +
          '1778                        000000000000000                  100');
        tempFile.Write('2300020000738609290061                         ASTRA TEC BVBA   ' +
          '         INDUSTRIELAAN 19          8810 LICHTERVELDE         000');
        tempFile.Write('2100030000NRGD00176 TBOINDNLOON1000000005313300170107001010000IN' +
          'V6205 MIN VOORSCHOT MIN TEVEEL GEST                1701070110100');
        tempFile.Write('2200030000                                                     6' +
          '1957 MI                     000000000000000                  100');
        tempFile.Write('2300030000390031747246                         IPL              ' +
          '                                                             000');
        tempFile.Write('21000400007409A3BWQ KGDTTNTERNG1000000004000000160107009010000  ' +
          '                                                   1701070110000');
        tempFile.Write('8011737010689443 EUR0BE                  0000000222672150170107 ' +
          '                                                                ');
        tempFile.Write('9               000012000000013878840000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000018010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 012737010689443 EUR0BE                  0000000222672150170107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OCGP00069BTBOGOVOVERS000000000122210018010700150000063' +
          '13;                                                1801070120100');
        tempFile.Write('2300010000443900193149                         C-MAC ELECTROMAG ' +
          'N.V.     INDUSTRIEZONE 28          9600 RONSE                000');
        tempFile.Write('8012737010689443 EUR0BE                  0000000223894250180107 ' +
          '                                                                ');
        tempFile.Write('9               000004000000000000000000000001222100            ' +
          '                                                               1');
        tempFile.Write('0000019010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 013737010689443 EUR0BE                  0000000223894250180107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OOQXA0AAO DOMNINDIN01100000000099810019010700501000110' +
          '7740784398863220107               0070140918      01901070130100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000OQEJ02375 TBOINDNLOON1000000003700000190107001010000FA' +
          'CTUUR F20060264                                    1901070130100');
        tempFile.Write('2200020000                                                     6' +
          '1961                        000000000000000                  100');
        tempFile.Write('2300020000447962409164                         DE GOUDEN KROON  ' +
          '         MARKTPLEIN 3-9            9940 EVERGEM              000');
        tempFile.Write('2100030000OQEJ02376 TBOINDNLOON10000000116142301901070010100002 ' +
          'AF MIN 2 VF MIN TEV BET                            1901070130100');
        tempFile.Write('2200030000                                                     7' +
          '0048 59                     000000000000000                  100');
        tempFile.Write('2300030000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100040000OL9414457JBBNEUBCRCL1000000000738811019010734150000000' +
          '352037019A2387                                     1901070131001');
        tempFile.Write('3100040001OL9414457JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200040001BUILDING AA                                           ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9414457JBBNEUBCRCL13415000010026710280720000287 6327' +
          '                                                             0 0');
        tempFile.Write('2100040003OL9414457JBBNEUBCRCL1000000000738811019010784150100110' +
          '5000000007388110000000007388110000100000000EUR     1901070131100');
        tempFile.Write('2200040003         000000007388110                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000OTJZ07706BOVSBBNONTVA0000000006470000190107001500000IN' +
          'VOICE 6227                                         1901070130100');
        tempFile.Write('2300050000293047693339                         NV PELEMAN INDUST' +
          'RIES     RIJKSWEG 7                2870    PUURS             000');
        tempFile.Write('8013737010689443 EUR0BE                  0000000221440030190107 ' +
          '                                                                ');
        tempFile.Write('9               000019000000016312330000000013858110            ' +
          '                                                               1');
        tempFile.Write('0000022010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 014737010689443 EUR0BE                  0000000221440030190107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PERF03204 TBOINDNLOON1000000000260000220107001010000IN' +
          'SCHRIJVING LED EUROPE                              2201070140100');
        tempFile.Write('2200010000                                                     D' +
          'IV6108                      000000000000000                  100');
        tempFile.Write('2300010000091013155653                         BAO              ' +
          '         GABRIELLE PETITSTRAAT 4B121080 BRUSSEL 8            000');
        tempFile.Write('8014737010689443 EUR0BE                  0000000221180030220107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000000260000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000023010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 015737010689443 EUR0BE                  0000000221180030220107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PQJJA0AM3 DOMALGDOV01100000000039663023010700501000110' +
          '774071599264523010775560-LF-0  2548125   414271   02301070150100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000PRFQ01851BTBOINDNLOON0000000000354000230107001500000FA' +
          'KT 7008    17/01/07   OUD IJZER                    2301070150100');
        tempFile.Write('2300020000449461774136                         DEKEUKELEIRE G & ' +
          'F BVBA   KOOPVAARDIJLAAN 49        9000  GENT                000');
        tempFile.Write('8015737010689443 EUR0BE                  0000000221137400230107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000000396630000000000354000            ' +
          '                                                               1');
        tempFile.Write('0000025010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 016737010689443 EUR0BE                  0000000221137400240107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000QPGEA0B06 DOMALGDOV01100000000117504025010700501000110' +
          '7740784372894250107I=0701631865 R=37005468        02501070160100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000QYVWA0ACA DOMNINDIN01100000000000456025010700501000110' +
          '7740784719367260107      070042466                02501070160100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100030000QYVWA0ACB DOMNINDIN01100000002232500025010700501000110' +
          '7740784719367260107      060534697                02501070160100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8016737010689443 EUR0BE                  0000000197632800250107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000023504600000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000026010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 017737010689443 EUR0BE                  0000000197632800250107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9456866JBBNEUNCRCL1000000010144318026010734150000000' +
          '352037026A2463                                     2601070171001');
        tempFile.Write('3100010001OL9456866JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9456866JBBNEUNCRCL13415000010026710280720000415 6235' +
          ' 6274 6310                                                   0 0');
        tempFile.Write('2100010003OL9456866JBBNEUNCRCL1000000010144318026010784150100110' +
          '5000000101443180000000101443180000100000000EUR     2601070171100');
        tempFile.Write('2200010003         000000101443180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000OL9456867KBBNKOSDIVKS100000000001089026010734137000000' +
          '352037026A2463                                     2601070171000');
        tempFile.Write('2100020001OL9456867KBBNKOSDIVKS1000000000009000260107841370130  ' +
          '                                                   2601070170000');
        tempFile.Write('2100020002OL9456867KBBNKOSDIVKS100000000000189026010784137011110' +
          '6000000000001890000000000009000002100000000200000002601070171100');
        tempFile.Write('220002000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9460898JBBOEUBCRECL000000001575055029010734150000000' +
          '352037026A6016                                     2601070171100');
        tempFile.Write('2200030000                                                     T' +
          '47A70124AD86                000000000000000                  001');
        tempFile.Write('3100030001OL9460898JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200030001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9460898JBBOEUBCRECL341500001002INV. 6347 / 27.12.200' +
          '6             INV. 6336 - 6339 VOM 22.12.2006                0 0');
        tempFile.Write('2100030003OL9460898JBBOEUBCRECL000000001575055029010784150100110' +
          '5000000015750550000000015750550000100000000EUR     2601070171100');
        tempFile.Write('2200030003         000000015750550                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000OL7079304 KGDBDCVBDEG1000000000470390250107309050000Uw' +
          ' bestelling                      34118493343       2601070171000');
    end;

    local procedure Write7022600005C(var tempFile: File)
    begin
        tempFile.Write('2100040001OL7079304 KGDBDCVBDEG100000000047039025010780905100110' +
          '5000000000470390000000000470390000063777500GBP     2601070171100');
        tempFile.Write('2200040001         000000000470390                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000RIQX00752BTBOINDNLOON0000000000224760260107001500000FA' +
          'CT. 6287                                           2601070170100');
        tempFile.Write('2300050000443900270143                         PRINTED CARPETS V' +
          'E.DE.BE. IND.PARK KL FRANKRIJK 62  9600  RONSE               000');
        tempFile.Write('8017737010689443 EUR0BE                  0000000314570010260107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000000481280000000117418490            ' +
          '                                                               1');
        tempFile.Write('0000029010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 018737010689443 EUR0BE                  0000000314570010260107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000RUIXA0AMU DOMALGDOV01100000000036048029010700501000110' +
          '774071599264529010774337-LF-0  2557333   414652   02901070180100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000RVQH03264 TBOINDNLOON100000000001800029010700101000110' +
          '1079934278829                                      2901070180100');
        tempFile.Write('2200020000                                                     D' +
          'IV7002                      000000000000000                  100');
        tempFile.Write('2300020000390044242058                         VORMETAL O W-VLAA' +
          'NDEREN   TRAMSTRAAT 61             9052 ZWIJNAARDE           000');
        tempFile.Write('2100030000RVQH03265 TBOINDNLOON100000000139379029010700101000110' +
          '1000043806412                                      2901070180100');
        tempFile.Write('2200030000                                                     6' +
          '/1933                       000000000000000                  100');
        tempFile.Write('2300030000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100040000SABYA0A4M DOMNINDIN01100000000034704029010700501000110' +
          '774076656127030010753220361 30/01                 02901070180100');
        tempFile.Write('22000400000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100050000OL9410136IUBOEUBTRFCS100000000019559026010734101000000' +
          '352037029B9459                                     2901070181100');
        tempFile.Write('2200050000                                                     7' +
          '0095                        000000000000000                  001');
        tempFile.Write('3100050001OL9410136IUBOEUBTRFCS341010001001PACK FEINDRAHTE      ' +
          '              AM BAUWEG 9-11                                 1 0');
        tempFile.Write('320005000151645 GUMMERSBACH DE               DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100050002OL9410136IUBOEUBTRFCS341010001002RECHNUNG7500167      ' +
          '                                                             0 1');
        tempFile.Write('3100050003OL9410136IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100050004OL9410136IUBOEUBTRFCS100000000019559026010784101100110' +
          '5000000000195590000000000195590000100000000EUR     2901070181100');
        tempFile.Write('2200050004         000000000195590                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8018737010689443 EUR0BE                  0000000312255110290107 ' +
          '                                                                ');
        tempFile.Write('9               000022000000002314900000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000030010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 019737010689443 EUR0BE                  0000000312255110290107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000SPUG00352 TBOINDNLOON1000000013915000300107001010000FA' +
          'CT ST07001                                         3001070190100');
        tempFile.Write('2200010000                                                     7' +
          '0117                        000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('2100020000SQOE00126 BHKDGLDTBLO1000000037058260300107101050000  ' +
          '                                                   3001070191000');
        tempFile.Write('2100020001SQNQ00001 TBOSOCOVERS1000000002050020300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020001449276421179                         KALFSVEL ALBERIK ' +
          '                                                             000');
        tempFile.Write('2100020002SQNQ00002 TBOSOCOVERS1000000003062420300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020002290019346063                         DE CLERCQ JOHN   ' +
          '                                                             000');
        tempFile.Write('2100020003SQNQ00003 TBOSOCOVERS1000000002262070300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020003001188642141                         DE BOODT SEBASTIA' +
          'AN                                                           000');
        tempFile.Write('2100020004SQNQ00004 TBOSOCOVERS1000000001567550300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020004780507355378                         VAN DEN BOSSCHE G' +
          'EERT                                                         000');
        tempFile.Write('2100020005SQNQ00005 TBOSOCOVERS1000000002047500300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020005979382731184                         ROMEYNS DIRK     ' +
          '                                                             000');
        tempFile.Write('2100020006SQNQ00006 TBOSOCOVERS1000000001875970300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020006777529118508                         VANDAMME PATRICK ' +
          '                                                             000');
        tempFile.Write('2100020007SQNQ00007 TBOSOCOVERS1000000001723310300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020007737446195801                         CANNOODT HENDRIK ' +
          '                                                             000');
        tempFile.Write('2100020008SQNQ00008 TBOSOCOVERS1000000001822980300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020008285032993567                         KIEKENS KRISTOF  ' +
          '                                                             000');
        tempFile.Write('2100020009SQNQ00009 TBOSOCOVERS1000000002295220300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020009738425378970                         DE MEERLEER GUIDO' +
          '                                                             000');
        tempFile.Write('2100020010SQNQ00010 TBOSOCOVERS1000000002553870300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020010290015438276                         GHIJSELEN JOZEF  ' +
          '                                                             000');
        tempFile.Write('2100020011SQNQ00011 TBOSOCOVERS1000000001721390300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020011001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100020012SQNQ00012 TBOSOCOVERS1000000001926210300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020012737101218432                         VAN DE SYPE DAVID' +
          '                                                             000');
        tempFile.Write('2100020013SQNQ00013 TBOSOCOVERS1000000001316770300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020013063952649462                         MOENS BRAM       ' +
          '                                                             000');
        tempFile.Write('2100020014SQNQ00014 TBOSOCOVERS1000000002086650300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020014293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100020015SQNQ00015 TBOSOCOVERS1000000001661660300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020015737005116185                         VAN DER PLAETSEN ' +
          'ISABELLE                                                     000');
        tempFile.Write('2100020016SQNQ00016 TBOSOCOVERS1000000001911840300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020016733163053996                         VERMEER PAUL     ' +
          '                                                             000');
        tempFile.Write('2100020017SQNQ00017 TBOSOCOVERS1000000001232440300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020017001347713047                         MINJAUW WOUTER   ' +
          '                                                             000');
        tempFile.Write('2100020018SQNQ00018 TBOSOCOVERS1000000001318760300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020018800226253891                         HERTOGE ANN      ' +
          '                                                             000');
        tempFile.Write('2100020019SQNQ00019 TBOSOCOVERS1000000001324090300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020019780539341736                         DE SAEDELEER SONJ' +
          'A                                                            000');
        tempFile.Write('2100020020SQNQ00020 TBOSOCOVERS1000000001297540300107501050000/A' +
          '/ LONEN 01/2007                                    3001070191100');
        tempFile.Write('2300020020063967633538                         COTTRELL ROY     ' +
          '                                                             000');
        tempFile.Write('8019737010689443 EUR0BE                  0000000261281850300107 ' +
          '                                                                ');
        tempFile.Write('9               000046000000050973260000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000031010772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 020737010689443 EUR0BE                  0000000261281850300107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TAAZA0D3Y IKLINNINNIG1000000000755750310107313410000  ' +
          '            INVESTERINGSKREDIET     726-3667975-97 3101070201000');
        tempFile.Write('2100010001TAAZA0D3Y IKLINNINNIG1000000000693670310107813410660  ' +
          '                                                   3101070200000');
        tempFile.Write('2100010002TAAZA0D3Y IKLINNINNIG1000000000062080310107813410020  ' +
          '                                                   3101070201000');
        tempFile.Write('2100020000TEBF03361 TBOINDNLOON1000000000147260310107001010000FA' +
          'CT 7006771RI                                       3101070200100');
        tempFile.Write('2200020000                                                     6' +
          '1818                        000000000000000                  100');
        tempFile.Write('2300020000230099456544                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100030000TEBF03362 TBOINDNLOON1000000000417140310107001010000FA' +
          'CT870084                                           3101070200100');
        tempFile.Write('2200030000                                                     7' +
          '0014                        000000000000000                  100');
        tempFile.Write('2300030000444564625163                         ALLCOMM          ' +
          '         BRUSSelseSTEENWEG 424-426 9050 LEDEBERG (GENT       000');
        tempFile.Write('2100040000TEBF03363 TBOINDNLOON1000000002074860310107001010000FA' +
          'CT2500281402 1403 86009 86010                      3101070200100');
        tempFile.Write('2200040000                                                     6' +
          '1788 92                     000000000000000                  100');
        tempFile.Write('2300040000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100050000TEBF03364 TBOINDNLOON1000000000400380310107001010000IN' +
          'V284121 84120 84787                                3101070200100');
        tempFile.Write('2200050000                                                     6' +
          '1862 87                     000000000000000                  100');
        tempFile.Write('2300050000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100060000TEBF03365 TBOINDNLOON100000000015125031010700101000110' +
          '1571033615082                                      3101070200100');
        tempFile.Write('2200060000                                                     7' +
          '0053                        000000000000000                  100');
        tempFile.Write('2300060000000171003118                         BELGACOM         ' +
          '         K ALBERT II LAAN 27       1030 BRUSSEL 3            000');
        tempFile.Write('2100070000TEBF03366 TBOINDNLOON1000000000428540310107001010000FA' +
          'CT CF6 23848                                       3101070200100');
        tempFile.Write('2200070000                                                     6' +
          '1898                        000000000000000                  100');
        tempFile.Write('2300070000210033172032                         CEGELEC          ' +
          '         WOLUWELN 60               1200 BRUSSEL              000');
        tempFile.Write('2100080000TEBF03367 TBOINDNLOON100000000295773031010700101000016' +
          '4682 683 161505 161625                             3101070200100');
        tempFile.Write('2200080000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300080000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100090000TEBF03368 TBOINDNLOON1000000000108750310107001010000FA' +
          'CT2007 015                                         3101070200100');
        tempFile.Write('2200090000                                                     7' +
          '0046                        000000000000000                  100');
        tempFile.Write('2300090000068211139826                         CONFISERIE SYLVIE' +
          '         ANTOON CATRIESTRAAT 48    9031 DRONGEN              000');
        tempFile.Write('2100100000TEBF03369 TBOINDNLOON1000000000546320310107001010000FA' +
          'CT602540                                           3101070200100');
        tempFile.Write('2200100000                                                     6' +
          '1951                        000000000000000                  100');
        tempFile.Write('2300100000462912815161                         DECOSTERE        ' +
          '         BURCHTHOF 10-11           8580 AVELGEM              000');
        tempFile.Write('2100110000TEBF03370 TBOINDNLOON1000000000421610310107001010000FT' +
          ' BRU0929445                                        3101070200100');
        tempFile.Write('2200110000                                                     6' +
          '1947                        000000000000000                  100');
        tempFile.Write('2300110000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100120000TEBF03371 TBOINDNLOON1000000000166910310107001010000FT' +
          ' BRU0915766                                        3101070200100');
        tempFile.Write('2200120000                                                     6' +
          '1873                        000000000000000                  100');
        tempFile.Write('2300120000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100130000TEBF03372 TBOINDNLOON1000000000068240310107001010000FT' +
          ' BRU0916695                                        3101070200100');
        tempFile.Write('2200130000                                                     6' +
          '1872                        000000000000000                  100');
        tempFile.Write('2300130000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100140000TEBF03373 TBOINDNLOON1000000002366570310107001010000FA' +
          'CT504859                                           3101070200100');
        tempFile.Write('2200140000                                                     6' +
          '1840                        000000000000000                  100');
        tempFile.Write('2300140000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100150000TEBF03374 TBOINDNLOON1000000010845780310107001010000CO' +
          'NS INV141                                          3101070200100');
        tempFile.Write('2200150000                                                     6' +
          '1771                        000000000000000                  100');
        tempFile.Write('2300150000720540538471                         FARNELL IN ONE   ' +
          '         RUE DE L''AEROPOSTALE 11   4460 GRACE-HOLLOGNE       000');
        tempFile.Write('2100160000TEBF03375 TBOINDNLOON100000000004937031010700101000110' +
          '1162033393150                                      3101070200100');
        tempFile.Write('2200160000                                                     7' +
          '0056                        000000000000000                  100');
        tempFile.Write('2300160000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100170000TEBF03376 TBOINDNLOON100000000030120031010700101000110' +
          '1612631487833                                      3101070200100');
        tempFile.Write('2200170000                                                     6' +
          '1880                        000000000000000                  100');
        tempFile.Write('2300170000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUXELLES            000');
        tempFile.Write('2100180000OL9453892IUBOEUBTRFCS100000000004356030010734101000000' +
          '352037031A1449                                     3101070201100');
        tempFile.Write('2200180000                                                     6' +
          '1914                        000000000000000                  001');
        tempFile.Write('3100180001OL9453892IUBOEUBTRFCS341010001001ERIKS BV             ' +
          '              TOERMALIJNSTRAAT 5                             1 0');
        tempFile.Write('32001800011800BK ALKMAAR NL                  NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100180002OL9453892IUBOEUBTRFCS341010001002FACT9101877291       ' +
          '                                                             0 1');
        tempFile.Write('3100180003OL9453892IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100180004OL9453892IUBOEUBTRFCS100000000004356030010784101100110' +
          '5000000000043560000000000043560000100000000EUR     3101070201100');
        tempFile.Write('2200180004         000000000043560                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100190000OL9453893IUBOEUBTRFCS100000000241410030010734101000000' +
          '352037031A1448                                     3101070201100');
        tempFile.Write('2200190000                                                     6' +
          '1938 939                    000000000000000                  001');
        tempFile.Write('3100190001OL9453893IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320019000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100190002OL9453893IUBOEUBTRFCS341010001002INV93954 93946       ' +
          '                                                             0 1');
        tempFile.Write('3100190003OL9453893IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100190004OL9453893IUBOEUBTRFCS100000000241410030010784101100110' +
          '5000000002414100000000002414100000100000000EUR     3101070201100');
        tempFile.Write('2200190004         000000002414100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100200000OL9453894IUBOEUBTRFCS100000000015780030010734101000000' +
          '352037031A1450                                     3101070201001');
        tempFile.Write('3100200001OL9453894IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002000017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100200002OL9453894IUBOEUBTRFCS341010001002INV22025799 2204     ' +
          '                                                             0 1');
        tempFile.Write('3100200003OL9453894IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100200004OL9453894IUBOEUBTRFCS100000000015780030010784101100110' +
          '5000000000157800000000000157800000100000000EUR     3101070201100');
        tempFile.Write('2200200004         000000000157800                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8020737010689443 EUR0BE                  0000000236458730310107 ' +
          '                                                                ');
        tempFile.Write('9               000076000000024823120000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000001020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 021737010689443 EUR0BE                  0000000236458730310107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TQTKA0M00 DOMNINDIN01100000000034704031010700501000110' +
          '774076656127001020753220361 01/02                 00102070210100');
        tempFile.Write('22000100000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100020000TXJT00179 TBOINDNLOON100000000010600001020700101000037' +
          '933 730678                                         0102070210100');
        tempFile.Write('2200020000                                                     7' +
          '0019                        000000000000000                  100');
        tempFile.Write('2300020000723540244980                         JEVEKA BV        ' +
          '                                                             000');
        tempFile.Write('2100030000TXJT00180 TBOINDNLOON100000000009062001020700101000110' +
          '1206195491314                                      0102070210100');
        tempFile.Write('2200030000                                                     6' +
          '1940                        000000000000000                  100');
        tempFile.Write('2300030000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100040000TXJT00181 TBOINDNLOON1000000000072600010207001010000FA' +
          'CT7235 7236                                        0102070210100');
        tempFile.Write('2200040000                                                     6' +
          '1888 89                     000000000000000                  100');
        tempFile.Write('2300040000000003149567                         MATEDEX          ' +
          '         AVENUE DE L''ARTISANAT 4   1420 BRAINE-L''ALLEU       000');
        tempFile.Write('2100050000TXJT00182 TBOINDNLOON1000000000343820010207001010000FA' +
          'CT60234                                            0102070210100');
        tempFile.Write('2200050000                                                     6' +
          '1926                        000000000000000                  100');
        tempFile.Write('2300050000271004538218                         NITRON NV        ' +
          '         RUE DE LA MAITRISE 2      1400 MONSTREUX            000');
        tempFile.Write('2100060000TXJT00183 TBOINDNLOON1000000000253160010207001010000FA' +
          'CT4100072921                                       0102070210100');
        tempFile.Write('2200060000                                                     6' +
          '1868                        000000000000000                  100');
        tempFile.Write('2300060000405012480190                         OTTO WOLFF NV    ' +
          '         DELLINGSTRAAT 57          2800 MECHELEN             000');
        tempFile.Write('2100070000TXJT00184 TBOINDNLOON1000000000433710010207001010000FA' +
          'CT 26105980 KLANT 3160                             0102070210100');
        tempFile.Write('2200070000                                                     6' +
          '1715                        000000000000000                  100');
        tempFile.Write('2300070000320032338254                         PEPPERL+ FUCHS NV' +
          '         METROPOOLSTRAAT 11        2900 SCHOTEN              000');
        tempFile.Write('2100080000TXJT00185 TBOINDNLOON1000000001252920010207001010000NO' +
          'TA1566700309                                       0102070210100');
        tempFile.Write('2200080000                                                     7' +
          '0009                        000000000000000                  100');
        tempFile.Write('2300080000001308220408                         ROMBAUT  C       ' +
          '         JAGERSSTR 20 BUS 9        2140 BORGERHOUT (AN       000');
        tempFile.Write('2100090000TXJT00186 TBOINDNLOON1000000007062250010207001010000DI' +
          'V INV                                              0102070210100');
        tempFile.Write('2200090000                                                     D' +
          'IV INV                      000000000000000                  100');
        tempFile.Write('2300090000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100100000TXJT00187 TBOINDNLOON1000000000977170010207001010000IN' +
          'V9168630 8632 8645 9288                            0102070210100');
        tempFile.Write('2200100000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300100000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100110000TXJT00188 TBOINDNLOON1000000004118200010207001010000FA' +
          'CT10052711 712 713 714 52772                       0102070210100');
        tempFile.Write('2200110000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300110000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100120000TXJT00189 TBOINDNLOON1000000000166830010207001010000IN' +
          'V680908 670323                                     0102070210100');
        tempFile.Write('2200120000                                                     6' +
          '1937 70                     000000000000000                  100');
        tempFile.Write('2300120000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100130000TXJT00190 TBOINDNLOON1000000000251680010207001010000FA' +
          'CT2006 514                                         0102070210100');
        tempFile.Write('2200130000                                                     6' +
          '1879                        000000000000000                  100');
        tempFile.Write('2300130000380020603881                         VANGO PRINTING   ' +
          '         HIJFTESTRAAT 55           9080 LOCHRISTI            000');
        tempFile.Write('2100140000UGRD00495BTBOGOVOVERS000000005844663001020700150000063' +
          '32 6334                                            0102070210100');
        tempFile.Write('2300140000482901003155                         BEKAERT COORDINAT' +
          'IECENTRUMBEKAERTSTRAAT 2           8550 ZWEVEGEM             000');
        tempFile.Write('8021737010689443 EUR0BE                  0000000279429360010207 ' +
          '                                                                ');
        tempFile.Write('9               000043000000015476000000000058446630            ' +
          '                                                               1');
        tempFile.Write('0000002020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 022737010689443 EUR0BE                  0000000279429360010207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('21000100007409A3C88 KGDTTNTERNG1000000005777620010207009010000  ' +
          '                                                   0202070220000');
        tempFile.Write('8022737010689443 EUR0BE                  0000000273651740020207 ' +
          '                                                                ');
        tempFile.Write('9               000003000000005777620000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000005020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 023737010689443 EUR0BE                  0000000273651740020207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VGCN03809 TBOINDNLOON100000000031052005020700101000110' +
          '1061135212219                                      0502070230100');
        tempFile.Write('2200010000                                                     D' +
          'IV7011                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('2100020000VGCN03810 TBOINDNLOON100000000095623005020700101000110' +
          '1061143082757                                      0502070230100');
        tempFile.Write('2200020000                                                     D' +
          'IV7012                      000000000000000                  100');
        tempFile.Write('2300020000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('8023737010689443 EUR0BE                  0000000272384990050207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001266750000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000006020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 024737010689443 EUR0BE                  0000000272384990050207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VVXKA0CN4 IKLINNINNIG1000000003660120060207313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0602070241000');
        tempFile.Write('2100010001VVXKA0CN4 IKLINNINNIG1000000003333330060207813410660  ' +
          '                                                   0602070240000');
        tempFile.Write('2100010002VVXKA0CN4 IKLINNINNIG1000000000326790060207813410020  ' +
          '                                                   0602070241000');
        tempFile.Write('2100020000OL7087022 KGDBDCVBDEG1000000000805180050207309050000Uw' +
          ' bestelling                      34110007257       0602070241000');
        tempFile.Write('2100020001OL7087022 KGDBDCVBDEG100000000080518005020780905100110' +
          '5000000000805180000000000805180000124195500USD     0602070241100');
        tempFile.Write('2200020001         000000000805180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9498991JBBNEUBCRCL1000000002381053007020734150000000' +
          '352037037B7942                                     0602070241001');
        tempFile.Write('3100030001OL9498991JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              THE JEFFREYS BUILDING, COWLEY RD               1 0');
        tempFile.Write('3200030001CAMBRIDGE CB4 0WS                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9498991JBBNEUBCRCL1341500001002INV 6346             ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9498991JBBNEUBCRCL1000000002381053007020784150100110' +
          '5000000023810530000000023810530000100000000EUR     0602070241100');
        tempFile.Write('2200030003         000000023810530                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8024737010689443 EUR0BE                  0000000291730220060207 ' +
          '                                                                ');
        tempFile.Write('9               000014000000004465300000000023810530            ' +
          '                                                               1');
        tempFile.Write('0000007020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
    end;

    local procedure Write7022600005D(var tempFile: File)
    begin
        tempFile.Write('1 025737010689443 EUR0BE                  0000000291730220060207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9407316JBBOEUBCRECL000000000740800008020734150000000' +
          '352037038A1971                                     0702070251100');
        tempFile.Write('2200010000                                                     4' +
          '550-70360575928             000000000000000                  001');
        tempFile.Write('3100010001OL9407316JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320001000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9407316JBBOEUBCRECL341500001002INVOICE  7003        ' +
          '              SUROWIEC                                       0 0');
        tempFile.Write('2100010003OL9407316JBBOEUBCRECL000000000740800008020784150100110' +
          '5000000007408000000000007408000000100000000EUR     0702070251100');
        tempFile.Write('2200010003         000000007408000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8025737010689443 EUR0BE                  0000000299138220070207 ' +
          '                                                                ');
        tempFile.Write('9               000009000000000000000000000007408000            ' +
          '                                                               1');
        tempFile.Write('0000008020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 026737010689443 EUR0BE                  0000000299138220070207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XASOA0AM2 DOMALGDOV01100000000070164008020700501000110' +
          '774071599264508020774422-LF-0  2569189   415130   00802070260100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000XBRY02063 TBOINDNLOON1000000009292560080207001010000FA' +
          'CT20061767 FACT20061768 MIN 2 CN                   0802070260100');
        tempFile.Write('2200020000                                                     6' +
          '1838 61                     000000000000000                  100');
        tempFile.Write('2300020000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100030000XBRY02064 TBOINDNLOON1000000003523520080207001010000FA' +
          'CT60317                                            0802070260100');
        tempFile.Write('2200030000                                                     6' +
          '1844                        000000000000000                  100');
        tempFile.Write('2300030000733028656658                         VAN VOXDALE      ' +
          '         LANGE WINKELHAAKSTRAAT 26 2060 BERCHEM (ANTW.       000');
        tempFile.Write('2100040000OL9432203IUBOEUBTRFCS100000000700000007020734101000000' +
          '352037039A1708                                     0802070261100');
        tempFile.Write('2200040000                                                     7' +
          '0131                        000000000000000                  001');
        tempFile.Write('3100040001OL9432203IUBOEUBTRFCS341010001001NICHIA EUROPE BV     ' +
          '              HORNWEG 18                                     1 0');
        tempFile.Write('32000400011045 AR AMSTERDAM NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9432203IUBOEUBTRFCS341010001002INVOICE 20070248     ' +
          '                                                             0 1');
        tempFile.Write('3100040003OL9432203IUBOEUBTRFCS341010001004BANK OF TOKYO - MITSU' +
          'BISHI UFJ (HOL                                               0 0');
        tempFile.Write('2100040004OL9432203IUBOEUBTRFCS100000000700000007020784101100110' +
          '5000000007000000000000007000000000100000000EUR     0802070261100');
        tempFile.Write('2200040004         000000007000000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8026737010689443 EUR0BE                  0000000278620500080207 ' +
          '                                                                ');
        tempFile.Write('9               000019000000020517720000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000009020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 027737010689443 EUR0BE                  0000000278620500080207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XNQXA0BCT IKLINNINNIG1000000000991820090207313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0902070271000');
        tempFile.Write('2100010001XNQXA0BCT IKLINNINNIG1000000000950930090207813410660  ' +
          '                                                   0902070270000');
        tempFile.Write('2100010002XNQXA0BCT IKLINNINNIG1000000000040890090207813410020  ' +
          '                                                   0902070271000');
        tempFile.Write('2100020000OL9459477JBBNEUBCRCL1000000003540602009020734150000000' +
          '352037040A2319                                     0902070271001');
        tempFile.Write('3100020001OL9459477JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9459477JBBNEUBCRCL13415000010026710280720000573 6308' +
          ' 6323 6342                                                   0 0');
        tempFile.Write('2100020003OL9459477JBBNEUBCRCL1000000003540602009020784150100110' +
          '5000000035406020000000035406020000100000000EUR     0902070271100');
        tempFile.Write('2200020003         000000035406020                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000XXNGA0B1O DOMNINDIN01100000000016858009020700501000110' +
          '7740784719367120207      070042467                00902070270100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100040000XXNGA0B1P DOMNINDIN01100000001610006009020700501000110' +
          '7740784719367120207      070042480                00902070270100');
        tempFile.Write('22000400000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8027737010689443 EUR0BE                  0000000296766060090207 ' +
          '                                                                ');
        tempFile.Write('9               000017000000017260460000000035406020            ' +
          '                                                               1');
        tempFile.Write('0000012020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 028737010689443 EUR0BE                  0000000296766060090207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YCTIA0APN DOMALGDOV01100000000028146012020700501000110' +
          '774071599264512020773518-LF-0  2573027   415350   01202070280100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000YCTIA0APO DOMALGDOV01100000000028702012020700501000110' +
          '774071599264512020773520-LF-0  2573028   415350   01202070280100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YCTIA0APP DOMALGDOV01100000000033999012020700501000110' +
          '774071599264512020773521-LF-0  2573029   415350   01202070280100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100040000YCUGA0CVW DOMALGDOV01100000000138109012020700501000110' +
          '7740784372894120207I=0701668378 R=37017803        01202070280100');
        tempFile.Write('22000400000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100050000YGQM02428LKKTOVSOVKUG100000000499090012020700319000112' +
          '45526145478490607    1435                          1202070280100');
        tempFile.Write('2300050000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8028737010689443 EUR0BE                  0000000289485600120207 ' +
          '                                                                ');
        tempFile.Write('9               000016000000007280460000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000013020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 029737010689443 EUR0BE                  0000000289485600120207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YPQM05627BOVSBBNONTVA000000000007026013020700150000017' +
          '01212007001422 6088 6088CN 632   9                 1302070290100');
        tempFile.Write('2300010000685668801833                         PHILIPS INNOVATIV' +
          'E APPLICATSTEENWEG OP GIERLE 417           TURNHOUT          000');
        tempFile.Write('2100020000YQCBA0AMJ DOMALGDOV01100000000028712013020700501000110' +
          '774071599264513020778359-LF-0  2576022   415418   01302070290100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YUPBA0E2M DOMUCVDIU01100000000002045013020700501000110' +
          '7740784397045130207227764/68145298                01302070290100');
        tempFile.Write('22000300000000938128                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         TAXIPOST         ' +
          '                                                             000');
        tempFile.Write('8029737010689443 EUR0BE                  0000000289248290130207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000307570000000000070260            ' +
          '                                                               1');
        tempFile.Write('0000014020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 030737010689443 EUR0BE                  0000000289248290130207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000ZFFP02090 TBOINDNLOON100000000072659014020700101000110' +
          '1061222384503                                      1402070300100');
        tempFile.Write('2200010000                                                     D' +
          'IV7019                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN AUTOS' +
          '         KON ALBERT II LAAN        1030 BRUSSEL 3            000');
        tempFile.Write('2100020000ZFFP02091 TBOINDNLOON1000000008558820140207001010000FA' +
          'CT 1491                                            1402070300100');
        tempFile.Write('2200020000                                                     7' +
          '0198                        000000000000000                  100');
        tempFile.Write('2300020000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100030000ZFFP02092 TBOINDNLOON1000000000035000140207001010000/A' +
          '/ EXP NOV DEC JAN                                  1402070300100');
        tempFile.Write('2200030000                                                     D' +
          'IV7013                      000000000000000                  100');
        tempFile.Write('2300030000780507355378                         VANDENBOSSCHE GEE' +
          'RT                                                           000');
        tempFile.Write('2100040000ZFFP02093 TBOINDNLOON1000000000316180140207001010000/A' +
          '/ EXP JAN07 HALT TUV                               1402070300100');
        tempFile.Write('2200040000                                                     D' +
          'IV7015                      000000000000000                  100');
        tempFile.Write('2300040000293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100050000ZFFP02094 TBOINDNLOON1000000000028100140207001010000/A' +
          '/ EXP AANKOOP MACRO                                1402070300100');
        tempFile.Write('2200050000                                                     D' +
          'IV7016                      000000000000000                  100');
        tempFile.Write('2300050000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100060000ZFFP02095 TBOINDNLOON1000000000020600140207001010000/A' +
          '/ EXP TREIN 080207                                 1402070300100');
        tempFile.Write('2200060000                                                     D' +
          'IV7020                      000000000000000                  100');
        tempFile.Write('2300060000001347713047                         WOUTER MINJAUW   ' +
          '         DENTERGEMSTRAAT 67        8780 OOSTROZEBEKE         000');
        tempFile.Write('2100070000ZFFP02096 TBOINDNLOON1000000000285200140207001010000/A' +
          '/ EXP SPLASH JAN FEB 07                            1402070300100');
        tempFile.Write('2200070000                                                     D' +
          'IV7022                      000000000000000                  100');
        tempFile.Write('2300070000290019346063                         DE CLERCQ JOHN   ' +
          '         BLEKTE 81                 9340 LEDE                 000');
        tempFile.Write('2100080000ZFFP02097 TBOINDNLOON100000000001050014020700101000110' +
          '1000060345518                                      1402070300100');
        tempFile.Write('2200080000                                                     D' +
          'IV7017                      000000000000000                  100');
        tempFile.Write('2300080000679205479140                         VOLMACHTEN       ' +
          '         MUNTCENTRUM               1000 BRUSSEL 1            000');
        tempFile.Write('2100090000ZFFP02098 TBOINDNLOON1000000015028010140207001010000FA' +
          'CT1865 1866 1867                                   1402070300100');
        tempFile.Write('2200090000                                                     6' +
          '1943 44                     000000000000000                  100');
        tempFile.Write('2300090000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100100000ZFFP02099 TBOINDNLOON1000000000037080140207001010000FA' +
          'CT 111700303 112600758                             1402070300100');
        tempFile.Write('2200100000                                                     6' +
          '1916 70                     000000000000000                  100');
        tempFile.Write('2300100000290028356050                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100110000ZFFP02100 TBOINDNLOON1000000003598200140207001010000DI' +
          'V INV                                              1402070300100');
        tempFile.Write('2200110000                                                     6' +
          '1805 83                     000000000000000                  100');
        tempFile.Write('2300110000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100120000ZFFP02101 TBOINDNLOON1000000000176620140207001010000FA' +
          'CT 576488 KL 014347                                1402070300100');
        tempFile.Write('2200120000                                                     6' +
          '1927                        000000000000000                  100');
        tempFile.Write('2300120000444961820157                         HANSSENS HOUT NV ' +
          '         PORT ARTHURLAAN 90        9000 GENT                 000');
        tempFile.Write('2100130000ZFFP02102 TBOINDNLOON1000000000562650140207001010000FA' +
          'CT 171144 KLANT 12032                              1402070300100');
        tempFile.Write('2200130000                                                     7' +
          '0090                        000000000000000                  100');
        tempFile.Write('2300130000685616301086                         NV FLUKE BELGIUM ' +
          '         LANGEVELDPARK UNIT7       1600 ST-PIETERS-LEE       000');
        tempFile.Write('2100140000ZFFP02103 TBOINDNLOON1000000000285310140207001010000FA' +
          'CT 0180688                                         1402070300100');
        tempFile.Write('2200140000                                                     6' +
          '1866                        000000000000000                  100');
        tempFile.Write('2300140000459250790127                         BINPAC           ' +
          '         IZ OOST, VRIJHEIDWEG 8    3700 TONGEREN             000');
        tempFile.Write('2100150000ZFFP02104 TBOINDNLOON1000000002860150140207001010000FA' +
          'CT 165279 280 161772 161896                        1402070300100');
        tempFile.Write('2200150000                                                     7' +
          '0092 87                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000ZFFP02105 TBOINDNLOON1000000001499400140207001010000BR' +
          'U0948706                                           1402070300100');
        tempFile.Write('2200160000                                                     7' +
          '0143                        000000000000000                  100');
        tempFile.Write('2300160000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100170000ZFFP02106 TBOINDNLOON1000000000092930140207001010000FA' +
          'CT614BE00972                                       1402070300100');
        tempFile.Write('2200170000                                                     6' +
          '1816                        000000000000000                  100');
        tempFile.Write('2300170000230099418451                         SEMIKRON         ' +
          '         LEUVENSESTEENWEG 510B9    1930 ZAVENTEM             000');
        tempFile.Write('2100180000ZFFP02107 TBOINDNLOON1000000000367840140207001010000FA' +
          'CT 70061248                                        1402070300100');
        tempFile.Write('2200180000                                                     6' +
          '1617                        000000000000000                  100');
        tempFile.Write('2300180000737427040422                         INTERCARE        ' +
          '         KORTE MAGERSTR 5          9050 GENTBRUGGE           000');
        tempFile.Write('2100190000ZFFP02108 TBOINDNLOON1000000000105390140207001010000FA' +
          'CT6069815                                          1402070300100');
        tempFile.Write('2200190000                                                     6' +
          '1921                        000000000000000                  100');
        tempFile.Write('2300190000230030914021                         VINK             ' +
          '         INDUSTRIEPARK 7           2220 HEIST-OP-DEN-B       000');
        tempFile.Write('2100200000ZFFP02109 TBOINDNLOON1000000000271800140207001010000FA' +
          'CT687804 685187 689218 695010 702325               1402070300100');
        tempFile.Write('2200200000                                                     7' +
          '0078 17                     000000000000000                  100');
        tempFile.Write('2300200000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100210000ZFFP02110 TBOINDNLOON1000000000623390140207001010000FA' +
          'CT 260620                                          1402070300100');
        tempFile.Write('2200210000                                                     6' +
          '1953                        000000000000000                  100');
        tempFile.Write('2300210000293021332779                         NOTEBAERT        ' +
          '         AALSTSTRAAT 6             9700 OUDENAARDE           000');
        tempFile.Write('2100220000ZFFP02111 TBOINDNLOON1000000003530760140207001010000FA' +
          'CT 28016690S01028                                  1402070300100');
        tempFile.Write('2200220000                                                     6' +
          '1751                        000000000000000                  100');
        tempFile.Write('2300220000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100230000ZFFP02112 TBOINDNLOON1000000001116250140207001010000FA' +
          'CT F06121401                                       1402070300100');
        tempFile.Write('2200230000                                                     6' +
          '1911                        000000000000000                  100');
        tempFile.Write('2300230000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100240000ZFFP02113 TBOINDNLOON1000000003254900140207001010000FA' +
          'CT 7241730                                         1402070300100');
        tempFile.Write('2200240000                                                     7' +
          '0021                        000000000000000                  100');
        tempFile.Write('2300240000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100250000ZFFP02114 TBOINDNLOON1000000000320650140207001010000FA' +
          'CT 23830                                           1402070300100');
        tempFile.Write('2200250000                                                     6' +
          '1886                        000000000000000                  100');
        tempFile.Write('2300250000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100260000ZFFP02115 TBOINDNLOON100000000092889014020700101000110' +
          '1000043806513                                      1402070300100');
        tempFile.Write('2200260000                                                     7' +
          '0100                        000000000000000                  100');
        tempFile.Write('2300260000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100270000ZFFP02116 TBOINDNLOON1000000003820840140207001010000FA' +
          'CT 111605534                                       1402070300100');
        tempFile.Write('2200270000                                                     6' +
          '1884                        000000000000000                  100');
        tempFile.Write('2300270000737502090534                         VANHOONACKER OUDE' +
          'NAARDE   WESTERING 31              9700 OUDENAARDE           000');
        tempFile.Write('2100280000OL9449950IUBOEUBTRFCS100000000070000013020734101000000' +
          '352037045A1181                                     1402070301100');
        tempFile.Write('2200280000                                                     7' +
          '0028                        000000000000000                  001');
        tempFile.Write('3100280001OL9449950IUBOEUBTRFCS341010001001VOGHT ELECTRONIC COMP' +
          'ONENT         VOGHT ELECTR PLATZ 1                           1 0');
        tempFile.Write('320028000194130 OBERNZELL DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100280002OL9449950IUBOEUBTRFCS341010001002INV1038385           ' +
          '                                                             0 1');
        tempFile.Write('3100280003OL9449950IUBOEUBTRFCS341010001004COMMERZBANK AG       ' +
          '                                                             0 0');
        tempFile.Write('2100280004OL9449950IUBOEUBTRFCS100000000070000013020784101100110' +
          '5000000000700000000000000700000000100000000EUR     1402070301100');
        tempFile.Write('2200280004         000000000700000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100290000OL9449951IUBOEUBTRFCS100000000024216013020734101000000' +
          '352037045A1180                                     1402070301100');
        tempFile.Write('2200290000                                                     3' +
          'INV                         000000000000000                  001');
        tempFile.Write('3100290001OL9449951IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002900017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100290002OL9449951IUBOEUBTRFCS341010001002INV22113733 2212     ' +
          '              3054 22123483                                  0 1');
        tempFile.Write('3100290003OL9449951IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100290004OL9449951IUBOEUBTRFCS100000000024216013020784101100110' +
          '5000000000242160000000000242160000100000000EUR     1402070301100');
        tempFile.Write('2200290004         000000000242160                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100300000OL9449952IUBOEUBTRFCS100000000086000013020734101000000' +
          '352037045A1179                                     1402070301001');
        tempFile.Write('3100300001OL9449952IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320030000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100300002OL9449952IUBOEUBTRFCS341010001002INVOICE 94090        ' +
          '                                                             0 1');
        tempFile.Write('3100300003OL9449952IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100300004OL9449952IUBOEUBTRFCS100000000086000013020784101100110' +
          '5000000000860000000000000860000000100000000EUR     1402070301100');
        tempFile.Write('2200300004         000000000860000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100310000OL9449953IUBOEUBTRFCS100000000008150013020734101000000' +
          '352037045A1178                                     1402070301100');
        tempFile.Write('2200310000                                                     D' +
          'IV7014                      000000000000000                  001');
        tempFile.Write('3100310001OL9449953IUBOEUBTRFCS341010001001ABONNEMENTENLAND     ' +
          '              POSTBUS 20                                     1 0');
        tempFile.Write('32003100011910AA UITGEEST NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100310002OL9449953IUBOEUBTRFCS341010001002FACTUUR 30370573     ' +
          '              KLANTNR 7682031                                0 1');
        tempFile.Write('3100310003OL9449953IUBOEUBTRFCS341010001004POSTBANK NV          ' +
          '                                                             0 0');
        tempFile.Write('2100310004OL9449953IUBOEUBTRFCS100000000008150013020784101100110' +
          '5000000000081500000000000081500000100000000EUR     1402070301100');
        tempFile.Write('2200310004         000000000081500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100320000OL9449954IUBOEUBTRFCS100000000179300013020734101000000' +
          '352037045A1182                                     1402070301001');
        tempFile.Write('3100320001OL9449954IUBOEUBTRFCS341010001001ZUKEN BV             ' +
          '              SCHEPENLAAN 18A                                1 0');
        tempFile.Write('32003200016002EE WEERT NL                    NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100320002OL9449954IUBOEUBTRFCS341010001002FACT ZNL100488       ' +
          '                                                             0 1');
        tempFile.Write('3100320003OL9449954IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100320004OL9449954IUBOEUBTRFCS100000000179300013020784101100110' +
          '5000000001793000000000001793000000100000000EUR     1402070301100');
        tempFile.Write('2200320004         000000001793000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8030737010689443 EUR0BE                  0000000237109580140207 ' +
          '                                                                ');
        tempFile.Write('9               000121000000052138710000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 031737010689443 EUR0BE                  0000000237109580150207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000AIBHA0AAN DOMNINDIN01100000000099810016020700501000110' +
          '7740784398863190207               0070142022      01602070310100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000AUBOA0CH4 DOMDCDDID01100000000003740016020700501000110' +
          '7740745036768190207F. 2007065205 DOMICIL.         01602070310100');
        tempFile.Write('22000200000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('8031737010689443 EUR0BE                  0000000236074080160207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001035500000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000019020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 032737010689443 EUR0BE                  0000000236074080140207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000BJUA00109 TBOINDNLOON1000000001352480190207001010000ON' +
          'KOSTEN BELCOMP EN VDVIJVER                         1902070320100');
        tempFile.Write('2200010000                                                     D' +
          'IV ONKO                     000000000000000                  100');
        tempFile.Write('2300010000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('8032737010689443 EUR0BE                  0000000234721600190207 ' +
          '                                                                ');
        tempFile.Write('9               000005000000001352480000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000020020772505D  0000000074789  INVERTO NV                0000' +
          '000000000430018420 00000                                       1');
        tempFile.Write('1 033737010689443 EUR0BE                  0000000234721600190207' +
          'INVERTO NV                KBC-Bedrijfsrekening               002');
        tempFile.Write('2100010000BNIVA0AMT DOMALGDOV01100000000039663020020700501000110' +
          '774071599264520020775560-LF-0  2584186   415775   02002070330100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000BOUJ01943 TBOINDNLOON100000001698636020020700101000110' +
          '1086444207901                                      2002070330100');
        tempFile.Write('2200020000                                                     A' +
          'ANSLJ 2                     000000000000000                  100');
        tempFile.Write('2300020000679200250133                         VENN BELAST      ' +
          '         G CROMMENLAAN 6 BUS 101   9050 LEDEBERG (GENT       000');
        tempFile.Write('2100030000BRLY08683BOVSBBNONTVA000000000030752020020700150000057' +
          '90131579 CREDITNOTA 010207                         2002070330100');
        tempFile.Write('2300030000000171003118                         Belgacom PO  NOOR' +
          'D        Stationsstraat, 58        2800 Mechelen             000');
        tempFile.Write('8033737010689443 EUR0BE                  0000000217646130200207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000017382990000000000307520            ' +
          '                                                               2');
    end;

    local procedure WriteOntVangenCODA20090416(var tempFile: File)
    begin
        tempFile.Write('0000016040972505        00094905  MGH 2002 NV               KRED' +
          'BEBB   00477997984 00000                                       2');
        tempFile.Write('10070734020020001 EUR0BE                  0000000099198010150409' +
          'MGH 2002 NV               KBC-Business Comfortrekening       067');
        tempFile.Write('2100010000MLFQA0DMQ IKKINNINNIG1000000000519120160409313410000  ' +
          '            KBC-INVESTERINGSKREDIET 726-5361582-84 16040907011 0');
        tempFile.Write('2300010000726536158284                                          ' +
          '                                                             0 0');
        tempFile.Write('2100010001MLFQA0DMQ IKKINNINNIG1000000000510000160409813410660  ' +
          '                                                   16040907000 0');
        tempFile.Write('2100010002MLFQA0DMQ IKKINNINNIG1000000000009120160409813410020  ' +
          '                                                   16040907010 0');
        tempFile.Write('2100020000MLNF04958BOVSBBNONTVA0000000049956120160409001500000FA' +
          '  VF09-0053 + 0083 + 0086 + 0023                   16040907001 0');
        tempFile.Write('2300020000551292970078                         SONAC GENT N V   ' +
          '                                                             0 1');
        tempFile.Write('3100020001MLNF04958BOVSBBNONTVA001500001001SONAC GENT N V       ' +
          '                                                             1 0');
        tempFile.Write('3200020001BRAAMTWEG                2         9042   MENDONK     ' +
          '                                                             0 0');
        tempFile.Write('2100030000MMASA0AKW DOMALGDOV01100000000049197016040900501000110' +
          '7740831711120160409KF09144333  3682144   464573   016040907001 0');
        tempFile.Write('22000300000426403684                                            ' +
          '                                                             1 0');
        tempFile.Write('2300030000                                     KBC LEASE BELGIUM' +
          '                                                             0 1');
        tempFile.Write('3100030001MMASA0AKW DOMALGDOV01005010001001KBC LEASE BELGIUM    ' +
          '                                                             0 0');
        tempFile.Write('2100040000MQSZ03583LKKTOVSOVKUG100000000044115016040900403000112' +
          '45526145493809534    1097                          16040907001 0');
        tempFile.Write('2300040000666000000483                                          ' +
          '                                                             0 0');
        tempFile.Write('2100050000MSSF04942 TBOINDNLOON100000003950213016040900101000110' +
          '1047799798426                                      16040907001 0');
        tempFile.Write('2300050000679200300047                         BTW ONTVANGSTEN  ' +
          '                                                             0 1');
        tempFile.Write('3100050001MSSF04942 TBOINDNLOON001010001001BTW ONTVANGSTEN      ' +
          '                                                             1 0');
        tempFile.Write('3200050001                                          BRUSSEL     ' +
          '                                                             0 0');
        tempFile.Write('2100060000MSSF04943 TBOINDNLOON1000000000250000160409001010000  ' +
          '                                                   16040907001 0');
        tempFile.Write('2300060000293003907034                         IME- VRIENDENKRIN' +
          'G                                                            0 1');
        tempFile.Write('3100060001MSSF04943 TBOINDNLOON001010001001IME- VRIENDENKRING   ' +
          '                                                             1 0');
        tempFile.Write('3200060001KON. ASTRIDLAAN 14                 2830   WILLEBROEK  ' +
          '                                                             0 0');
        tempFile.Write('2100070000MUKH00749 BHKDGLDTBNL1000000036218470160409101070000  ' +
          '                                                   16040907010 0');
        tempFile.Write('2100070001MTWT00001 TBOGOVOVERS100000000081238016040950107000110' +
          '1520142058864                                      16040907001 0');
        tempFile.Write('2300070001000013190077                         ELECTRABEL C/O   ' +
          '                                                             0 1');
        tempFile.Write('3100070002MTWT00001 TBOGOVOVERS501070001001ELECTRABEL C/O       ' +
          '                                                             1 0');
        tempFile.Write('3200070002FRANKLIN ROOSEVELTLAAN 1           9000   GENT        ' +
          '                                                             0 0');
        tempFile.Write('2100070003MTWT00002 TBOGOVOVERS100000000084702016040950107000110' +
          '1550051894888                                      16040907001 0');
        tempFile.Write('2300070003000013190077                         ELECTRABEL C/O   ' +
          '                                                             0 1');
        tempFile.Write('3100070004MTWT00002 TBOGOVOVERS501070001001ELECTRABEL C/O       ' +
          '                                                             1 0');
        tempFile.Write('3200070004FRANKLIN ROOSEVELTLAAN 1           9000   GENT        ' +
          '                                                             0 0');
        tempFile.Write('2100070005MTWT00003 TBOGOVOVERS100000000029899016040950107000110' +
          '1093030330570                                      16040907001 0');
        tempFile.Write('2300070005230014660053                         PREMED VZW       ' +
          '                                                             0 1');
        tempFile.Write('3100070006MTWT00003 TBOGOVOVERS501070001001PREMED VZW           ' +
          '                                                             1 0');
        tempFile.Write('3200070006TIENSEVEST 61 BUS 2                3010   KESSEL-LO (L' +
          'EU                                                           0 0');
        tempFile.Write('2100070007MTWT00004 TBOGOVOVERS100000000004291016040950107000110' +
          '1033504946620                                      16040907001 0');
        tempFile.Write('2300070007405050461148                         TELENET NV       ' +
          '                                                             0 1');
        tempFile.Write('3100070008MTWT00004 TBOGOVOVERS501070001001TELENET NV           ' +
          '                                                             1 0');
        tempFile.Write('3200070008LIERSESTWG 4                       2800   MECHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070009MTWT00005 TBOGOVOVERS100000000287254016040950107000110' +
          '1110129030024                                      16040907001 0');
        tempFile.Write('2300070009452920385120                         FISCO-CONSULT BVB' +
          'A                                                            0 1');
        tempFile.Write('3100070010MTWT00005 TBOGOVOVERS501070001001FISCO-CONSULT BVBA   ' +
          '                                                             1 0');
        tempFile.Write('3200070010KAUTERSHOEK 21 BUS1                3290   DIEST       ' +
          '                                                             0 0');
        tempFile.Write('2100070011MTWT00006 TBOGOVOVERS1000000000464410160409501070000V1' +
          '/40900695                                          16040907001 0');
        tempFile.Write('2300070011001412713050                         OFFICE PLUS NV   ' +
          '                                                             0 1');
        tempFile.Write('3100070012MTWT00006 TBOGOVOVERS501070001001OFFICE PLUS NV       ' +
          '                                                             1 0');
        tempFile.Write('3200070012HENRY FORDLAAN 18                  3600   GENK        ' +
          '                                                             0 0');
        tempFile.Write('2100070013MTWT00007 TBOGOVOVERS100000000044891016040950107000020' +
          '0900199                                            16040907001 0');
        tempFile.Write('2300070013068235204819                         SRT GROUP SPRL TR' +
          'ANSPORT A                                                    0 1');
        tempFile.Write('3100070014MTWT00007 TBOGOVOVERS501070001001SRT GROUP SPRL TRANSP' +
          'ORT A                                                        1 0');
        tempFile.Write('3200070014NIEUWBRUGSTRAAT 71                 1830   MACHELEN (BT' +
          '.)                                                           0 0');
        tempFile.Write('2100070015MTWT00008 TBOGOVOVERS100000000020570016040950107000090' +
          '084                                                16040907001 0');
        tempFile.Write('2300070015103010290051                         MEA              ' +
          '                                                             0 1');
        tempFile.Write('3100070016MTWT00008 TBOGOVOVERS501070001001MEA                  ' +
          '                                                             1 0');
        tempFile.Write('3200070016KRAANKINDERSSTRAAT 3-7             9000   GENT        ' +
          '                                                             0 0');
        tempFile.Write('2100070017MTWT00009 TBOGOVOVERS100000000542107016040950107000091' +
          '0051478                                            16040907001 0');
        tempFile.Write('2300070017210052380052                         SEW CARON-VECTOR ' +
          ' SA                                                          0 1');
        tempFile.Write('3100070018MTWT00009 TBOGOVOVERS501070001001SEW CARON-VECTOR  SA ' +
          '                                                             1 0');
        tempFile.Write('3200070018AV. EIFFEL 5                       1300   WAVRE       ' +
          '                                                             0 0');
        tempFile.Write('2100070019MTWT00010 TBOGOVOVERS100000000137692016040950107000000' +
          '1737                                               16040907001 0');
        tempFile.Write('2300070019210081374059                         SAFETY-KLEEN BELG' +
          'IUM SA                                                       0 1');
        tempFile.Write('3100070020MTWT00010 TBOGOVOVERS501070001001SAFETY-KLEEN BELGIUM ' +
          'SA                                                           1 0');
        tempFile.Write('3200070020INDUSTRIELAAN 130                  1070   ANDERLECHT  ' +
          '                                                             0 0');
        tempFile.Write('2100070021MTWT00011 TBOGOVOVERS100000000012289016040950107000001' +
          '0/29014893                                         16040907001 0');
        tempFile.Write('2300070021220004005732                         ROMBOUTS         ' +
          '                                                             0 1');
        tempFile.Write('3100070022MTWT00011 TBOGOVOVERS501070001001ROMBOUTS             ' +
          '                                                             1 0');
        tempFile.Write('3200070022ANTWERPSESTEENWEG 136              2630   AARTSELAAR  ' +
          '                                                             0 0');
        tempFile.Write('2100070023MTWT00012 TBOGOVOVERS100000000009099016040950107000086' +
          '00385276                                           16040907001 0');
        tempFile.Write('2300070023271001598815                         MEWA SERVIBEL NV ' +
          '                                                             0 1');
        tempFile.Write('3100070024MTWT00012 TBOGOVOVERS501070001001MEWA SERVIBEL NV     ' +
          '                                                             1 0');
        tempFile.Write('3200070024MOTSTRAAT 54                       2800   MECHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070025MTWT00013 TBOGOVOVERS100000000086288016040950107000000' +
          '090808                                             16040907001 0');
        tempFile.Write('2300070025293018439048                         TRANSMO NV       ' +
          '                                                             0 1');
        tempFile.Write('3100070026MTWT00013 TBOGOVOVERS501070001001TRANSMO NV           ' +
          '                                                             1 0');
        tempFile.Write('3200070026PEDRO COLOMALAAN 9                 2880   BORNEM      ' +
          '                                                             0 0');
        tempFile.Write('2100070027MTWT00014 TBOGOVOVERS100000000235950016040950107000090' +
          '030 90031 90032 90033                              16040907001 0');
        tempFile.Write('2300070027310068982951                         WOODTOOLS - INTER' +
          'PROFIEL                                                      0 1');
        tempFile.Write('3100070028MTWT00014 TBOGOVOVERS501070001001WOODTOOLS - INTERPROF' +
          'IEL                                                          1 0');
        tempFile.Write('3200070028PEUTIESESTEENWEG 120               1830   MACHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070029MTWT00015 TBOGOVOVERS100000000031952016040950107000042' +
          '006009 MRT/09                                      16040907001 0');
        tempFile.Write('2300070029310100270097                         DKV BELGIUM NV   ' +
          '                                                             0 1');
        tempFile.Write('3100070030MTWT00015 TBOGOVOVERS501070001001DKV BELGIUM NV       ' +
          '                                                             1 0');
        tempFile.Write('3200070030BD BISCHOFFSHEIMLAAN 1-8           1000   BRUSSEL     ' +
          '                                                             0 0');
        tempFile.Write('2100070031MTWT00016 TBOGOVOVERS1000000000572330160409501070000FZ' +
          '2900524                                            16040907001 0');
        tempFile.Write('2300070031310180545075                         OKA.BE           ' +
          '                                                             0 1');
        tempFile.Write('3100070032MTWT00016 TBOGOVOVERS501070001001OKA.BE               ' +
          '                                                             1 0');
        tempFile.Write('3200070032MAALBEEKWEG 8                      1930   ZAVENTEM    ' +
          '                                                             0 0');
        tempFile.Write('2100070033MTWT00017 TBOGOVOVERS100000000039348016040950107000041' +
          '2-200904.23100004                                  16040907001 0');
        tempFile.Write('2300070033330025371921                         GYKIERE BVBA GARA' +
          'GE CITRO‰                                                    0 1');
        tempFile.Write('3100070034MTWT00017 TBOGOVOVERS501070001001GYKIERE BVBA GARAGE C' +
          'ITRO‰                                                        1 0');
        tempFile.Write('3200070034PERKSESTEENWEG 21 K                1820   MELSBROEK   ' +
          '                                                             0 0');
        tempFile.Write('2100070035MTWT00018 TBOGOVOVERS100000000003436016040950107000027' +
          '04904/00018                                        16040907001 0');
        tempFile.Write('2300070035335002828406                         CARGLASS         ' +
          '                                                             0 1');
        tempFile.Write('3100070036MTWT00018 TBOGOVOVERS501070001001CARGLASS             ' +
          '                                                             1 0');
        tempFile.Write('3200070036MECHelseSTEENWEG 289 TOTAA         1800   VILVOORDE   ' +
          '                                                             0 0');
        tempFile.Write('2100070037MTWT00019 TBOGOVOVERS100000000037740016040950107000090' +
          '1711 901966                                        16040907001 0');
        tempFile.Write('2300070037363003860135                         TRABELINT        ' +
          '                                                             0 1');
        tempFile.Write('3100070038MTWT00019 TBOGOVOVERS501070001001TRABELINT            ' +
          '                                                             1 0');
        tempFile.Write('3200070038BRUCARGO 750                       1931   BRUCARGO ZAV' +
          'EN                                                           0 0');
        tempFile.Write('2100070039MTWT00020 TBOGOVOVERS100000001257536016040950107000009' +
          '004800 09004801 09004802 09004803 09004804 0900480516040907001 0');
        tempFile.Write('2200070039 09004806 09004807 09004808 09004809 09004810 ... ... ' +
          '                                                             1 0');
        tempFile.Write('2300070039414004622185                         MANO             ' +
          '                                                             0 1');
        tempFile.Write('3100070040MTWT00020 TBOGOVOVERS501070001001MANO                 ' +
          '                                                             1 0');
        tempFile.Write('3200070040JUBELLAAN 78                       2800   MECHELEN    ' +
          '                                                             0 0');
        tempFile.Write('2100070041MTWT00021 TBOGOVOVERS100000000114648016040950107000024' +
          '0598                                               16040907001 0');
        tempFile.Write('2300070041450054900137                         ACTIEF INTERIM   ' +
          '                                                             0 1');
        tempFile.Write('3100070042MTWT00021 TBOGOVOVERS501070001001ACTIEF INTERIM       ' +
          '                                                             1 0');
        tempFile.Write('3200070042J.B. NOW‚LEI 28                    1800   VILVOORDE   ' +
          '                                                             0 0');
        tempFile.Write('2100070043MTWT00022 TBOGOVOVERS1000000000344850160409501070000F0' +
          '9/020333                                           16040907001 0');
        tempFile.Write('2300070043453717465139                         TRIUS N.V. ICT SO' +
          'LUTIONS                                                      0 1');
        tempFile.Write('3100070044MTWT00022 TBOGOVOVERS501070001001TRIUS N.V. ICT SOLUTI' +
          'ONS                                                          1 0');
        tempFile.Write('3200070044HENRY FORDLAAN 18                  3600   GENK        ' +
          '                                                             0 0');
        tempFile.Write('2100070045MTWT00023 TBOGOVOVERS100000000037090016040950107000029' +
          '2437                                               16040907001 0');
        tempFile.Write('2300070045464111058181                         PRECISA MOTOREN N' +
          '.V.                                                          0 1');
        tempFile.Write('3100070046MTWT00023 TBOGOVOVERS501070001001PRECISA MOTOREN N.V. ' +
          '                                                             1 0');
        tempFile.Write('3200070046NOORDSTRAAT 14                     8560   MOORSELE    ' +
          '                                                             0 0');
        tempFile.Write('2100070047MTWT00024 TBOGOVOVERS1000000000140610160409501070000H7' +
          '3574/F72827                                        16040907001 0');
        tempFile.Write('2300070047466715460186                         VAN MARCKE       ' +
          '                                                             0 1');
        tempFile.Write('3100070048MTWT00024 TBOGOVOVERS501070001001VAN MARCKE           ' +
          '                                                             1 0');
        tempFile.Write('3200070048MECHelseSTEENWEG 287               1800   VILVOORDE   ' +
          '                                                             0 0');
        tempFile.Write('2100070049MTWT00025 TBOGOVOVERS100000000004334016040950107000020' +
          '09475430 2009483363                                16040907001 0');
        tempFile.Write('2300070049720520419762                         UPS              ' +
          '                                                             0 1');
        tempFile.Write('3100070050MTWT00025 TBOGOVOVERS501070001001UPS                  ' +
          '                                                             1 0');
        tempFile.Write('3200070050WOLUWELAAN 156                     1831   DIEGEM      ' +
          '                                                             0 0');
        tempFile.Write('2100070051MTWT00026 TBOGOVOVERS100000000207520016040950107000009' +
          '0308                                               16040907001 0');
        tempFile.Write('2300070051733054566065                         BRANDMARK        ' +
          '                                                             0 1');
        tempFile.Write('3100070052MTWT00026 TBOGOVOVERS501070001001BRANDMARK            ' +
          '                                                             1 0');
        tempFile.Write('3200070052PANNENHUISSTRAAT 359               2500   LIER        ' +
          '                                                             0 0');
        tempFile.Write('2100070053MTWT00027 TBOGOVOVERS100000000159753016040950107000062' +
          '1372280 19-04                                      16040907011 0');
        tempFile.Write('2300070053860080627691                         AXA BELGIUM NV   ' +
          '                                                             0 1');
        tempFile.Write('3100070054MTWT00027 TBOGOVOVERS501070001001AXA BELGIUM NV       ' +
          '                                                             1 0');
        tempFile.Write('3200070054SINTE VEERLEDREEF 1                1820   STEENOKKERZE' +
          'EL                                                           0 0');
        tempFile.Write('2100080000MWKM00651 BHKDGLDOUBO1000000014959870150409241010000  ' +
          '                                                   16040907010 0');
        tempFile.Write('2100080001MVYVA0AY3BSCTOBBUBVFF100000000169500015040960101000043' +
          '573706                                             16040907001 0');
        tempFile.Write('2200080001                                                      ' +
          '                                  NDEAFIHH                   1 0');
        tempFile.Write('2300080001FI1022901800127402                   VEM MOTORS FINLAN' +
          'D OY                                                         0 1');
        tempFile.Write('3100080002MVYVA0AY3BSCTOBBUBVFF601010001001VEM MOTORS FINLAND OY' +
          '                                                             1 0');
        tempFile.Write('3200080002KEH.NREUNA 4                                          ' +
          '                                                             0 0');
        tempFile.Write('2100080003MVYVA0AY4BSCTOBBUBVFF1000000012936320150409601010000F0' +
          '901097                                             16040907001 0');
        tempFile.Write('2200080003                                                      ' +
          '                                  CCBPFRPPLIL                1 0');
        tempFile.Write('2300080003FR7613507001651441331210901          NT TRANSMISSIONS ' +
          '                                                             0 1');
        tempFile.Write('3100080004MVYVA0AY4BSCTOBBUBVFF601010001001NT TRANSMISSIONS     ' +
          '                                                             1 0');
        tempFile.Write('3200080004Z.I. PLACE GUTENBERG                                  ' +
          '                                                             0 0');
        tempFile.Write('2100080005MVYVA0AY5BSCTOBBUBVFF100000000032855015040960101000084' +
          '596                                                16040907011 0');
        tempFile.Write('2200080005                                                      ' +
          '                                  BNPAFRPPCNA                1 0');
        tempFile.Write('2300080005FR7630004004160001002239136          PTP INDUSTRY SAS ' +
          '                                                             0 1');
        tempFile.Write('3100080006MVYVA0AY5BSCTOBBUBVFF601010001001PTP INDUSTRY SAS     ' +
          '                                                             1 0');
        tempFile.Write('3200080006LA BELLE ORGE                                         ' +
          '                                                             0 0');
        tempFile.Write('8070734020020001 EUR0BE                  0000000056771420160409 ' +
          '                                                               0');
        tempFile.Write('9               000150000000092382710000000049956120            ' +
          '                                                               2');
    end;

    local procedure WriteOntVangenCODAScenario373926(var tempFile: File)
    begin
        tempFile.Write('0000010092072505        00503659  HERMANS  JOHAN            KRED' +
          'BEBB   00820877643 00000                                       2');
        tempFile.Write('10157734028222864 EUR0BE                  0000000048168530080920C & F HERMANS' +
          ' BV          KBC-Business Comfortrekening       157');
        tempFile.Write('2100010000HEPW03654 TK4TBNINNIG1000000000837630100920313010000Terugbetaling' +
          '    420-3332395-64                      10092015711 0');
        tempFile.Write('2300010000420333239564                                                     ' +
          '                                                  0 0');
        tempFile.Write('2100010001HEPW03654 TK4TBNINNIG1000000000832340100920813010550' +
          '                                                     10092015700 0');
        tempFile.Write('2100010002HEPW03654 TK4TBNINNIG1000000000005290100920813010020' +
          '                                                     10092015710 0');
        tempFile.Write('2100020000HGJT40426 SDDBDTBDREC1000000000078930100920005010001' +
          '127100920110BE65ZZZ0403063902                  BEB20010092015701 0');
        tempFile.Write('22000200000000400-7606481-71           I 0717945808 R B0880966' +
          ' I0000016740433-110407179458082020  GEBABEBB                   1 0');
        tempFile.Write('2300020000BE62210047007161                     TOTAL BELGIUM' +
          '                      //20200908-BEDO1                      0    0 1');
        tempFile.Write('3100020001HGJT40426 SDDBDTBDREC005010001001TOTAL BELGIUM' +
          '                                                                     1 0');
        tempFile.Write('3200020001                                              ' +
          '                        BE65ZZZ0403063902                            0 0');
        tempFile.Write('2100030000HOUY01870 BKTUBBBECPG1000000000001500100920304' +
          '0200011136703420000000801251289904056009092012195IKEA ZAVEN10092015711 0');
        tempFile.Write('2200030000TEM-FOZAVENTEM  000000000001500000100000000EUR0000000' +
          '                                                              1 0');
        tempFile.Write('2300030000                                                     ' +
          '                   00000                                      0 0');
        tempFile.Write('2100030001HOUY01870 BKTUBBBECPG1000000000001500100920804021000' +
          '                                                     10092015710 0');
        tempFile.Write('2100040000HOUY01871 BKTUBBBECPG1000000000000300100920304020001' +
          '1136703420000000801231948304165809092012205MERA CLAEY10092015711 0');
        tempFile.Write('2200040000S BVBARUDDERVOOR000000000000300000100000000EUR0000000' +
          '                                                              1 0');
        tempFile.Write('2300040000                                                     ' +
          '                   00000                                      0 0');
        tempFile.Write('2100040001HOUY01871 BKTUBBBECPG1000000000000300100920804021000' +
          '                                                     10092015710 0');
        tempFile.Write('8157734028222864 EUR0BE                  0000000047250170100920' +
          '                                                                0');

        tempFile.Write('9               000019000000000918360000000000000000' +
          '                                                                           2');
    end;

    local procedure WriteCODA1MultipleA(var tempFile: File)
    begin
        tempFile.Write('0000002010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 001290004614187 EUR0BE                  0000000291493520291206' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000HIRQA1H6L BKTKOSKOKFG1000000000020000010107303370000Aa' +
          'nrekening kaartbijdrage   5526 1454 7849 0607      0201070011000');
        tempFile.Write('2100010001HIRQA1H6L BKTKOSKOKFG1000000000020000010107803370060  ' +
          '                                                   0201070011000');
        tempFile.Write('2100020000HIWC00001 CKZKOSKOSBK1000000000018700020107013370000  ' +
          '  COMMERCIELE KREDIETZAAK MET REFERTE      727-64440201070010100');
        tempFile.Write('2200020000961-49                                                ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9426419JBBOEUBCRECL000000000799200003010734150000000' +
          '352037002A3545                                     0201070011100');
        tempFile.Write('2200030000                                                     4' +
          '550-63629896326             000000000000000                  001');
        tempFile.Write('3100030001OL9426419JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320003000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9426419JBBOEUBCRECL341500001002INVOIC               ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9426419JBBOEUBCRECL000000000799200003010784150100110' +
          '5000000007992000000000007992000000100000000EUR     0201070011100');
        tempFile.Write('2200030003         000000007992000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000HNOA00002BTBOGOVOVERS000000000151250002010700150000062' +
          '91                                                 0201070010100');
        tempFile.Write('2300040000472302320181                         TEAM LASERPRESS N' +
          'V        JACQUES PARYSLAAN 8       9940 EVERGEM              000');
        tempFile.Write('2100050000HOUP00283BTBOINDNLOON0000000001024930020107001500000FT' +
          ' 6314                                              0201070010100');
        tempFile.Write('2300050000738010356689                         EVILO NV         ' +
          '         SCHELDESTRAAT 35 A        8553 OTEGEM               000');
        tempFile.Write('2100060000OL9447899JBBNEUBCRCL1000000003378098003010734150000000' +
          '352037002C0877                                     0201070011001');
        tempFile.Write('3100060001OL9447899JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              3110001                                        1 0');
        tempFile.Write('320006000129                                                    ' +
          '                                                             0 1');
        tempFile.Write('3100060002OL9447899JBBNEUBCRCL1341500001002INV 6320             ' +
          '                                                             0 0');
        tempFile.Write('2100060003OL9447899JBBNEUBCRCL1000000003378098003010784150100110' +
          '5000000033780980000000033780980000100000000EUR     0201070011100');
        tempFile.Write('2200060003         000000033780980                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8001290004614187 EUR0BE                  0000000335765230020107 ' +
          '                                                                ');
        tempFile.Write('9               000023000000000038700000000044310410            ' +
          '                                                               1');
        tempFile.Write('0000003010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 002290004614187 EUR0BE                  0000000335765230020107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9460983JBBOEUBCRECL000000002220652004010734150000000' +
          '352037003A7683                                     0301070021100');
        tempFile.Write('2200010000                                                     T' +
          '47A70102AU78                000000000000000                  001');
        tempFile.Write('3100010001OL9460983JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200010001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9460983JBBOEUBCRECL341500001002INV. 6318 / 30.11.200' +
          '6             INV. 6315 / 24.11.2006                         1 0');
        tempFile.Write('3200010002./. BELASTUNG 17004039 / 19.12.2006                   ' +
          '                                                             0 0');
        tempFile.Write('2100010003OL9460983JBBOEUBCRECL000000002220652004010784150100110' +
          '5000000022206520000000022206520000100000000EUR     0301070021100');
        tempFile.Write('2200010003         000000022206520                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8002290004614187 EUR0BE                  0000000357971750030107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000022206520            ' +
          '                                                               1');
        tempFile.Write('0000005010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 003290004614187 EUR0BE                  0000000357971750040107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JCRL02237 TBOINDNLOON1000000013310000050107001010000FA' +
          'CT ST06012                                         0501070030100');
        tempFile.Write('2200010000                                                     6' +
          '/1900                       000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('8003290004614187 EUR0BE                  0000000344661750050107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000013310000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000008010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 004290004614187 EUR0BE                  0000000344661750050107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000JQQJA0CUQ IKLINNINNIG1000000003670020060107313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0801070041000');
        tempFile.Write('2100010001JQQJA0CUQ IKLINNINNIG1000000003333330060107813410660  ' +
          '                                                   0801070040000');
        tempFile.Write('2100010002JQQJA0CUQ IKLINNINNIG1000000000336690060107813410020  ' +
          '                                                   0801070041000');
        tempFile.Write('2100020000OL9441847JBBNEUNCRCL1000000005292465008010734150000000' +
          '352037008A2593                                     0801070041001');
        tempFile.Write('3100020001OL9441847JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9441847JBBNEUNCRCL13415000010026710280720000130 6306' +
          ' 6309 6311                                                   0 0');
        tempFile.Write('2100020003OL9441847JBBNEUNCRCL1000000005292465008010784150100110' +
          '5000000052924650000000052924650000100000000EUR     0801070041100');
        tempFile.Write('2200020003         000000052924650                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9441848KBBNKOSDIVKS100000000001089008010734137000000' +
          '352037008A2593                                     0801070041000');
        tempFile.Write('2100030001OL9441848KBBNKOSDIVKS1000000000009000080107841370130  ' +
          '                                                   0801070040000');
        tempFile.Write('2100030002OL9441848KBBNKOSDIVKS100000000000189008010784137011110' +
          '6000000000001890000000000009000002100000000200000000801070041100');
        tempFile.Write('220003000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000KBIS00253 TBOINDNLOON100000000304899008010700101000110' +
          '1006000522050                                      0801070040100');
        tempFile.Write('2200040000                                                     6' +
          '1823                        000000000000000                  100');
        tempFile.Write('2300040000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100050000KBIS00254 TBOINDNLOON100000000001479008010700101000110' +
          '1006000523969                                      0801070040100');
        tempFile.Write('2200050000                                                     6' +
          '1867                        000000000000000                  100');
        tempFile.Write('2300050000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('2100060000KBIS00255 TBOINDNLOON100000000360973008010700101000110' +
          '1007000047537                                      0801070040100');
        tempFile.Write('2200060000                                                     6' +
          '/1941                       000000000000000                  100');
        tempFile.Write('2300060000828998553034                         HERBERIGS SPRL   ' +
          '         WIJNGAARDSTRAAT 5         9700 OUDENAARDE           000');
        tempFile.Write('8004290004614187 EUR0BE                  0000000387231980080107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000010354420000000052924650            ' +
          '                                                               1');
        tempFile.Write('0000009010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 005290004614187 EUR0BE                  0000000387231980080107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KFXWA0BSQ IKLINNINNIG1000000000991820090107313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0901070051000');
        tempFile.Write('2100010001KFXWA0BSQ IKLINNINNIG1000000000947310090107813410660  ' +
          '                                                   0901070050000');
        tempFile.Write('2100010002KFXWA0BSQ IKLINNINNIG1000000000044510090107813410020  ' +
          '                                                   0901070051000');
        tempFile.Write('2100020000KGNAA0ANJ DOMALGDOV01100000000070164009010700501000110' +
          '774071599264509010774422-LF-0  2532992   413664   00901070050100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000KHMC01793 TBOINDNLOON1000000000553560090107001010000IN' +
          'V 7006237 RI KLNR 92164                            0901070050100');
        tempFile.Write('2200030000                                                     6' +
          '1695                        000000000000000                  100');
        tempFile.Write('2300030000437751551186                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100040000KHMC01794 TBOINDNLOON1000000000209570090107001010000FA' +
          'CT2070004583                                       0901070050100');
        tempFile.Write('2200040000                                                     6' +
          '1744                        000000000000000                  100');
        tempFile.Write('2300040000390041400059                         AIR COMPACT BELGI' +
          'UM NV    BRUSSelseSTWG 427         9050 LEDEBERG (GENT       000');
        tempFile.Write('2100050000KHMC01795 TBOINDNLOON100000000011173009010700101000009' +
          '0059 2000 06006310                                 0901070050100');
        tempFile.Write('2200050000                                                     6' +
          '/1575                       000000000000000                  100');
        tempFile.Write('2300050000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100060000KHMC01796 TBOINDNLOON100000000010682009010700101000009' +
          '0059 2000 06006658                                 0901070050100');
        tempFile.Write('2200060000                                                     6' +
          '/1615                       000000000000000                  100');
        tempFile.Write('2300060000293018003760                         ATEM             ' +
          '         BEDRIJVENPARK DE VEERT 4  2830 WILLEBROEK           000');
        tempFile.Write('2100070000KHMC01797 TBOINDNLOON100000000015277009010700101000110' +
          '1200601108664                                      0901070050100');
        tempFile.Write('2200070000                                                     6' +
          '1668                        000000000000000                  100');
        tempFile.Write('2300070000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100080000KHMC01798 TBOINDNLOON100000000032818009010700101000110' +
          '1200601236986                                      0901070050100');
        tempFile.Write('2200080000                                                     6' +
          '1798                        000000000000000                  100');
        tempFile.Write('2300080000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100090000KHMC01799 TBOINDNLOON100000000008494009010700101000110' +
          '1200641227460                                      0901070050100');
        tempFile.Write('2200090000                                                     6' +
          '1804                        000000000000000                  100');
        tempFile.Write('2300090000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100100000KHMC01800 TBOINDNLOON100000000017015009010700101000110' +
          '1200601285284                                      0901070050100');
        tempFile.Write('2200100000                                                     6' +
          '1813                        000000000000000                  100');
        tempFile.Write('2300100000220057681084                         AUTOBAR BELGIUM S' +
          'A        BOOMSESTEENWEG 73         2630 AARTSELAAR           000');
        tempFile.Write('2100110000KHMC01801 TBOINDNLOON1000000000512740090107001010000FA' +
          'CT 28016149 S01 028                                0901070050100');
        tempFile.Write('2200110000                                                     6' +
          '1592                        000000000000000                  100');
        tempFile.Write('2300110000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100120000KHMC01802 TBOINDNLOON1000000000902630090107001010000FT' +
          '111602572 602741 602867 602892 602981 603069 6030720901070050100');
        tempFile.Write('2200120000                                                     6' +
          '1607829                     000000000000000                  100');
        tempFile.Write('2300120000447964515175                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100130000KHMC01803 TBOINDNLOON100000000076807009010700101000110' +
          '1009005562044                                      0901070050100');
        tempFile.Write('2200130000                                                     6' +
          '1671                        000000000000000                  100');
        tempFile.Write('2300130000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100140000KHMC01804 TBOINDNLOON100000000076807009010700101000110' +
          '1009005671875                                      0901070050100');
        tempFile.Write('2200140000                                                     6' +
          '1874                        000000000000000                  100');
        tempFile.Write('2300140000220043968823                         CARE             ' +
          '         LUCHTHAVENLEI 7B BUS 2    2100 DEURNE (ANTW.)       000');
        tempFile.Write('2100150000KHMC01805 TBOINDNLOON1000000010619930090107001010000IN' +
          'V164091 164092 164170 164168 164169 164184         0901070050100');
        tempFile.Write('2200150000                                                     6' +
          '1704712                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000KHMC01806 TBOINDNLOON1000000005455890090107001010000IN' +
          'V 06111601 111602 111603                           0901070050100');
        tempFile.Write('2200160000                                                     6' +
          '168789                      000000000000000                  100');
        tempFile.Write('2300160000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100170000KHMC01807 TBOINDNLOON1000000000135680090107001010000BR' +
          'U0905683                                           0901070050100');
        tempFile.Write('2200170000                                                     6' +
          '1779                        000000000000000                  100');
        tempFile.Write('2300170000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100180000KHMC01808 TBOINDNLOON1000000000732900090107001010000IN' +
          'V122810 KLANT822346                                0901070050100');
        tempFile.Write('2200180000                                                     6' +
          '1667                        000000000000000                  100');
        tempFile.Write('2300180000825601419034                         EBV              ' +
          '         EXCELSIORLN 68            1930 ZAVENTEM             000');
        tempFile.Write('2100190000KHMC01809 TBOINDNLOON1000000000961950090107001010000IN' +
          'V 712559 717757 720476                             0901070050100');
        tempFile.Write('2200190000                                                     6' +
          '1731885                     000000000000000                  100');
        tempFile.Write('2300190000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100200000KHMC01810 TBOINDNLOON1000000002447810090107001010000FA' +
          'CT504658                                           0901070050100');
        tempFile.Write('2200200000                                                     6' +
          '1727                        000000000000000                  100');
        tempFile.Write('2300200000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100210000KHMC01811 TBOINDNLOON1000000000467990090107001010000IN' +
          'V96133105 TO96142988                               0901070050100');
        tempFile.Write('2200210000                                                     6' +
          '149991                      000000000000000                  100');
        tempFile.Write('2300210000733031146932                         FABORY           ' +
          '         ZWEDENSTRAAT 4            9940 EVERGEM              000');
        tempFile.Write('2100220000KHMC01812 TBOINDNLOON100000000007132009010700101000110' +
          '1162033288470                                      0901070050100');
        tempFile.Write('2200220000                                                     6' +
          '1854                        000000000000000                  100');
        tempFile.Write('2300220000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100230000KHMC01813 TBOINDNLOON1000000001408000090107001010000IN' +
          'V841175 853828                                     0901070050100');
        tempFile.Write('2200230000                                                     6' +
          '176449                      000000000000000                  100');
        tempFile.Write('2300230000720520635687                         FUTURE ELECTRONIC' +
          'S        BRANDSTR 15A              9160 LOKEREN              000');
        tempFile.Write('2100240000KHMC01814 TBOINDNLOON1000000001275340090107001010000IN' +
          'V108687                                            0901070050100');
        tempFile.Write('2200240000                                                     6' +
          '1683                        000000000000000                  100');
        tempFile.Write('2300240000410065152192                         GIVATEC          ' +
          '         INDUSTRIEWEG 5            3001 HEVERLEE             000');
        tempFile.Write('2100250000KHMC01815 TBOINDNLOON1000000000045190090107001010000FA' +
          'CT94886                                            0901070050100');
        tempFile.Write('2200250000                                                     6' +
          '1769                        000000000000000                  100');
        tempFile.Write('2300250000335043322468                         IMES OOST VLAANDE' +
          'REN      KORTE MAGERSTRAAT 3       9050 GENTBRUGGE           000');
        tempFile.Write('2100260000KHMC01816 TBOINDNLOON1000000001830000090107001010000IN' +
          'V191537                                            0901070050100');
        tempFile.Write('2200260000                                                     6' +
          '1526                        000000000000000                  100');
        tempFile.Write('2300260000340182596777                         LEM INSTRUMENTS  ' +
          '                                   1000 BRUSSEL 1            000');
        tempFile.Write('2100270000KHMC01817 TBOINDNLOON100000000017302009010700101000110' +
          '1206193754509                                      0901070050100');
        tempFile.Write('2200270000                                                     6' +
          '1776                        000000000000000                  100');
        tempFile.Write('2300270000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100280000KHMC01818 TBOINDNLOON1000000000832470090107001010000IN' +
          'V4082537                                           0901070050100');
        tempFile.Write('2200280000                                                     6' +
          '1662                        000000000000000                  100');
        tempFile.Write('2300280000552270880026                         MISCO            ' +
          '         POSTBUS 156               1930 ZAVENTEM             000');
        tempFile.Write('2100290000KHMC01819 TBOINDNLOON1000000000457380090107001010000IN' +
          'V VG062501107                                      0901070050100');
        tempFile.Write('2200290000                                                     6' +
          '1654                        000000000000000                  100');
        tempFile.Write('2300290000414520300154                         NIJKERK ELECTRONI' +
          'CS       NOORDERLAAN 111           2030 ANTWERPEN 3          000');
        tempFile.Write('2100300000KHMC01820 TBOINDNLOON1000000000146170090107001010000IN' +
          'VOICE 60107183RI CUSTOMER 42103297                 0901070050100');
        tempFile.Write('2200300000                                                     6' +
          '1738                        000000000000000                  100');
        tempFile.Write('2300300000432401944101                         OMRON            ' +
          '         STATIONSSTRAAT 24         1702 GROOT-BIJGAARD       000');
        tempFile.Write('2100310000KHMC01821 TBOINDNLOON1000000000572330090107001010000IN' +
          'V23807                                             0901070050100');
        tempFile.Write('2200310000                                                     6' +
          '1835                        000000000000000                  100');
        tempFile.Write('2300310000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100320000KHMC01822 TBOINDNLOON1000000000223730090107001010000IN' +
          'V61331 60554                                       0901070050100');
        tempFile.Write('2200320000                                                     6' +
          '164882                      000000000000000                  100');
        tempFile.Write('2300320000437750008179                         PHOENIX CONTACT  ' +
          '         MINERVASTRAAT 10-12       1930 ZAVENTEM             000');
        tempFile.Write('2100330000KHMC01823 TBOINDNLOON100000000640961009010700101000110' +
          '1060680430143                                      0901070050100');
        tempFile.Write('2200330000                                                     6' +
          '1834                        000000000000000                  100');
        tempFile.Write('2300330000001446507648                         RANDSTAD PROF    ' +
          '         HEIZEL ESPLANADE          1020 BRUSSEL 2            000');
        tempFile.Write('2100340000KHMC01824 TBOINDNLOON1000000001053590090107001010000IN' +
          'V6299051                                           0901070050100');
        tempFile.Write('2200340000                                                     6' +
          '1773                        000000000000000                  100');
        tempFile.Write('2300340000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUSSEL              000');
        tempFile.Write('2100350000KHMC01825 TBOINDNLOON1000000000533320090107001010000IN' +
          'V553060 557754                                     0901070050100');
        tempFile.Write('2200350000                                                     6' +
          '169465                      000000000000000                  100');
        tempFile.Write('2300350000310161043025                         RS COMPONENTS    ' +
          '         BD PAEPSEMLAAN 22         1070 ANDERLECHT           000');
        tempFile.Write('2100360000KHMC01826 TBOINDNLOON1000000006014750090107001010000IN' +
          'V4495806 TO4555463                                 0901070050100');
        tempFile.Write('2200360000                                                     6' +
          '150491                      000000000000000                  100');
        tempFile.Write('2300360000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100370000KHMC01827 TBOINDNLOON1000000002420000090107001010000IN' +
          'V50780                                             0901070050100');
        tempFile.Write('2200370000                                                     6' +
          '1801                        000000000000000                  100');
        tempFile.Write('2300370000430084575196                         SEHER            ' +
          '         ASSESTEENWEG 117 2        1740 TERNAT               000');
        tempFile.Write('2100380000KHMC01828 TBOINDNLOON1000000000470090090107001010000IN' +
          'V9166859                                           0901070050100');
        tempFile.Write('2200380000                                                     6' +
          '1642                        000000000000000                  100');
        tempFile.Write('2300380000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100390000KHMC01829 TBOINDNLOON100000000048822009010700101000110' +
          '1630311096035                                      0901070050100');
        tempFile.Write('2200390000                                                     6' +
          '1752                        000000000000000                  100');
        tempFile.Write('2300390000407050860119                         STANDAARD BOEKHAN' +
          'DEL      INDUSTRIEPARK NOORD 28A   9100 ST-NIKLAAS           000');
        tempFile.Write('2100400000KHMC01830 TBOINDNLOON1000000001064250090107001010000IN' +
          'V10052583 10052504 10052509                        0901070050100');
        tempFile.Write('2200400000                                                     6' +
          '1780 82                     000000000000000                  100');
        tempFile.Write('2300400000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100410000KHMC01831 TBOINDNLOON1000000000715970090107001010000DI' +
          'V INV                                              0901070050100');
        tempFile.Write('2200410000                                                     6' +
          '1899                        000000000000000                  100');
        tempFile.Write('2300410000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100420000KHMC01832 TBOINDNLOON1000000000380000090107001010000IN' +
          'V80274362                                          0901070050100');
        tempFile.Write('2200420000                                                     6' +
          '1736                        000000000000000                  100');
        tempFile.Write('2300420000720540560602                         TYCO EL          ' +
          '                                                             000');
        tempFile.Write('2100430000KHMC01833 TBOINDNLOON1000000000323740090107001010000IN' +
          'V611791 KLANT 4268                                 0901070050100');
        tempFile.Write('2200430000                                                     6' +
          '1777                        000000000000000                  100');
        tempFile.Write('2300430000068241941669                         VANSICHEN        ' +
          '         BREDEWEG 62               3723 KORTESSEM            000');
        tempFile.Write('2100440000KHMC01834 TBOINDNLOON1000000000527620090107001010000IN' +
          'V601717                                            0901070050100');
        tempFile.Write('2200440000                                                     6' +
          '1698                        000000000000000                  100');
        tempFile.Write('2300440000446064891124                         VANDEVYVER       ' +
          '         BENELUXLN 1               9060 ZELZATE              000');
        tempFile.Write('2100450000KHMC01835 TBOINDNLOON1000000000024200090107001010000FA' +
          'CT602844 8612                                      0901070050100');
        tempFile.Write('2200450000                                                     6' +
          '1665                        000000000000000                  100');
        tempFile.Write('2300450000645141021968                         VENTOMATIC       ' +
          '         CHRYSANTENSTRAAT 59B      9820 MERELBEKE            000');
        tempFile.Write('2100460000KHMC01836 TBOINDNLOON1000000004416500090107001010000IN' +
          'V606087                                            0901070050100');
        tempFile.Write('2200460000                                                     6' +
          '1845                        000000000000000                  100');
        tempFile.Write('2300460000443563835141                         VANSTEENBRUGGHE N' +
          'V        BERCHEMWEG 95             9700 OUDENAARDE           000');
        tempFile.Write('2100470000KHMC01837 TBOINDNLOON1000000001698840090107001010000IN' +
          'V223602                                            0901070050100');
        tempFile.Write('2200470000                                                     6' +
          '1750                        000000000000000                  100');
        tempFile.Write('2300470000891374071719                         WYNANT           ' +
          '         AALSTSTRAAT 28            9700 OUDENAARDE           000');
        tempFile.Write('2100480000OL9470740IUBOEUBTRFCS100000000059200008010734101000000' +
          '352037009A1848                                     0901070051100');
        tempFile.Write('2200480000                                                     6' +
          '1802                        000000000000000                  001');
        tempFile.Write('3100480001OL9470740IUBOEUBTRFCS341010001001AMECHA BV            ' +
          '              GRASBEEMD 15A                                  1 0');
        tempFile.Write('32004800015705 DE HELMOND NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100480002OL9470740IUBOEUBTRFCS341010001002FACT06223            ' +
          '                                                             0 1');
        tempFile.Write('3100480003OL9470740IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100480004OL9470740IUBOEUBTRFCS100000000059200008010784101100110' +
          '5000000000592000000000000592000000100000000EUR     0901070051100');
        tempFile.Write('2200480004         000000000592000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100490000OL9470741IUBOEUBTRFCS100000000065000008010734101000000' +
          '352037009A1849                                     0901070051100');
        tempFile.Write('2200490000                                                     6' +
          '1864 65                     000000000000000                  001');
        tempFile.Write('3100490001OL9470741IUBOEUBTRFCS341010001001BALKHAUSEN           ' +
          '              RUDOLF DIESEL STR 17                           1 0');
        tempFile.Write('320049000128857 SYKE DE                      DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100490002OL9470741IUBOEUBTRFCS341010001002INVOICE 0703023      ' +
          '              0703024                                        0 1');
        tempFile.Write('3100490003OL9470741IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100490004OL9470741IUBOEUBTRFCS100000000065000008010784101100110' +
          '5000000000650000000000000650000000100000000EUR     0901070051100');
        tempFile.Write('2200490004         000000000650000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100500000OL9470742IUBOEUBTRFCS100000000002690008010734101000000' +
          '352037009A1850                                     0901070051100');
        tempFile.Write('2200500000                                                     6' +
          '1841                        000000000000000                  001');
        tempFile.Write('3100500001OL9470742IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320050000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
    end;

    local procedure WriteCODA1MultipleB(var tempFile: File)
    begin
        tempFile.Write('3100500002OL9470742IUBOEUBTRFCS341010001002INV93750             ' +
          '                                                             0 1');
        tempFile.Write('3100500003OL9470742IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100500004OL9470742IUBOEUBTRFCS100000000002690008010784101100110' +
          '5000000000026900000000000026900000100000000EUR     0901070051100');
        tempFile.Write('2200500004         000000000026900                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100510000OL9470743IUBOEUBTRFCS100000000033000008010734101000000' +
          '352037009A1851                                     0901070051100');
        tempFile.Write('2200510000                                                     6' +
          '1713                        000000000000000                  001');
        tempFile.Write('3100510001OL9470743IUBOEUBTRFCS341010001001KEMA QUALITY BV      ' +
          '              UTRECHTSESTEENWEG 310                          1 0');
        tempFile.Write('32005100016812AR ARNHEM NL                   NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100510002OL9470743IUBOEUBTRFCS34101000100217268 2188747        ' +
          '                                                             0 1');
        tempFile.Write('3100510003OL9470743IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100510004OL9470743IUBOEUBTRFCS100000000033000008010784101100110' +
          '5000000000330000000000000330000000100000000EUR     0901070051100');
        tempFile.Write('2200510004         000000000330000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100520000OL9470744IUBOEUBTRFCS100000000026095008010734101000000' +
          '352037009A1857                                     0901070051100');
        tempFile.Write('2200520000                                                     6' +
          '1739                        000000000000000                  001');
        tempFile.Write('3100520001OL9470744IUBOEUBTRFCS341010001001TTI INC              ' +
          '              GANGHOFERSTRASSE 34                            1 0');
        tempFile.Write('320052000182216 MAISACH-GERNLINDEN DE        DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100520002OL9470744IUBOEUBTRFCS341010001002INV E00888030        ' +
          '                                                             0 1');
        tempFile.Write('3100520003OL9470744IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100520004OL9470744IUBOEUBTRFCS100000000026095008010784101100110' +
          '5000000000260950000000000260950000100000000EUR     0901070051100');
        tempFile.Write('2200520004         000000000260950                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100530000OL9470745IUBOEUBTRFCS100000000272921008010734101000000' +
          '352037009A1858                                     0901070051100');
        tempFile.Write('2200530000                                                     6' +
          '1692 1719 1853              000000000000000                  001');
        tempFile.Write('3100530001OL9470745IUBOEUBTRFCS341010001001VERMEULEN PRINTSSERVI' +
          'CE            HELMONDSEWEG 7B                                1 0');
        tempFile.Write('32005300015735 RA AARLE-RIXTEL NL            NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100530002OL9470745IUBOEUBTRFCS341010001002INV IO6 07298 07     ' +
          '              430                                            0 1');
        tempFile.Write('3100530003OL9470745IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100530004OL9470745IUBOEUBTRFCS100000000272921008010784101100110' +
          '5000000002729210000000002729210000100000000EUR     0901070051100');
        tempFile.Write('2200530004         000000002729210                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100540000OL9470746IUBOEUBTRFCS100000000037500008010734101000000' +
          '352037009A1852                                     0901070051100');
        tempFile.Write('2200540000                                                     6' +
          '1728                        000000000000000                  001');
        tempFile.Write('3100540001OL9470746IUBOEUBTRFCS341010001001KONING EN HARTMAN BV ' +
          '              POSTBUS 416                                    1 0');
        tempFile.Write('32005400011000AK AMSTERDAM NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100540002OL9470746IUBOEUBTRFCS341010001002INV5100052503        ' +
          '                                                             0 1');
        tempFile.Write('3100540003OL9470746IUBOEUBTRFCS341010001004VAN LANSCHOT F BANKIE' +
          'RS NV                                                        0 0');
        tempFile.Write('2100540004OL9470746IUBOEUBTRFCS100000000037500008010784101100110' +
          '5000000000375000000000000375000000100000000EUR     0901070051100');
        tempFile.Write('2200540004         000000000375000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100550000OL9470747IUBOEUBTRFCS100000000173224008010734101000000' +
          '352037009A1853                                     0901070051100');
        tempFile.Write('2200550000                                                     6' +
          '1882                        000000000000000                  001');
        tempFile.Write('3100550001OL9470747IUBOEUBTRFCS341010001001PHILIPS OVAR         ' +
          '              EN109/IC1 ZONA IND OVAR                        1 0');
        tempFile.Write('32005500013880728 OVAR PT                    PT                 ' +
          '                                                             0 1');
        tempFile.Write('3100550002OL9470747IUBOEUBTRFCS341010001002INV789179            ' +
          '                                                             0 1');
        tempFile.Write('3100550003OL9470747IUBOEUBTRFCS341010001004BANCO BILBAO VIZCAYA ' +
          'ARGENTARIA (PO                                               0 0');
        tempFile.Write('2100550004OL9470747IUBOEUBTRFCS100000000173224008010784101100110' +
          '5000000001732240000000001732240000100000000EUR     0901070051100');
        tempFile.Write('2200550004         000000001732240                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100560000OL9470749IUBOEUBTRFCS100000000362410008010734101000000' +
          '352037009A1854                                     0901070051100');
        tempFile.Write('2200560000                                                     6' +
          '169647                      000000000000000                  001');
        tempFile.Write('3100560001OL9470749IUBOEUBTRFCS341010001001PIHER                ' +
          '              AMBACHTSSTR 13B                                1 0');
        tempFile.Write('32005600013861 HR NIJKERK NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100560002OL9470749IUBOEUBTRFCS341010001002INV110640 110692     ' +
          '                                                             0 1');
        tempFile.Write('3100560003OL9470749IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100560004OL9470749IUBOEUBTRFCS100000000362410008010784101100110' +
          '5000000003624100000000003624100000100000000EUR     0901070051100');
        tempFile.Write('2200560004         000000003624100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100570000OL9470750IUBOEUBTRFCS100000000025001008010734101000000' +
          '352037009A1856                                     0901070051100');
        tempFile.Write('2200570000                                                     6' +
          '1814                        000000000000000                  001');
        tempFile.Write('3100570001OL9470750IUBOEUBTRFCS341010001001BV SNIJ-UNIE HIFI    ' +
          '              ZOUTKETEN 23                                   1 0');
        tempFile.Write('32005700011601EX ENKHUIZEN NL                NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100570002OL9470750IUBOEUBTRFCS341010001002INV267116 KLANT2     ' +
          '              136                                            0 1');
        tempFile.Write('3100570003OL9470750IUBOEUBTRFCS341010001004INTERNATIONALE NEDERL' +
          'ANDEN BANK NV                                                0 0');
        tempFile.Write('2100570004OL9470750IUBOEUBTRFCS100000000025001008010784101100110' +
          '5000000000250010000000000250010000100000000EUR     0901070051100');
        tempFile.Write('2200570004         000000000250010                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100580000OL9470751IUBOEUNTRFCS100000001604164008010734101000000' +
          '352037009A1855                                     0901070051001');
        tempFile.Write('3100580001OL9470751IUBOEUNTRFCS341010001001PUNCH TECHNIX NV     ' +
          '              KROMMESPIERINGWEG 289B                         1 0');
        tempFile.Write('32005800012141BS VIJFHUIZEN NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100580002OL9470751IUBOEUNTRFCS341010001002INV204700680         ' +
          '              FACTUUR204700252 PUNCH TECHNIX NV              0 1');
        tempFile.Write('3100580003OL9470751IUBOEUNTRFCS341010001004BANQUE ARTESIA NEDERL' +
          'AND                                                          0 0');
        tempFile.Write('2100580004OL9470751IUBOEUNTRFCS100000001604164008010784101100110' +
          '5000000016041640000000016041640000100000000EUR     0901070051100');
        tempFile.Write('2200580004         000000016041640                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100590000OL9470752KUBOKOSDIVKS100000000001210008010734137000000' +
          '352037009A1855                                     0901070051000');
        tempFile.Write('2100590001OL9470752KUBOKOSDIVKS1000000000010000080107841370260  ' +
          '                                                   0901070050000');
        tempFile.Write('2100590002OL9470752KUBOKOSDIVKS100000000000210008010784137011110' +
          '6000000000002100000000000010000002100000000200000000901070051100');
        tempFile.Write('220059000200002100                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100600000KJXV14365BOVSBBNONTVA000000000061147009010700150000062' +
          '90                                                 0901070050100');
        tempFile.Write('220060000010/062-260985                                         ' +
          '                            000000000000000                  100');
        tempFile.Write('2300600000260035911186                         GO TO SA         ' +
          '         CHEMIN DE HAMEAU 25       6120    HAM-SUR-HEURE     000');
        tempFile.Write('21006100007409A3A5G KGDTTNTERNG1000000008000000080107009010000  ' +
          '                                                   0901070050000');
        tempFile.Write('8005290004614187 EUR0BE                  0000000292458810090107 ' +
          '                                                                ');
        tempFile.Write('9               000238000000095384640000000000611470            ' +
          '                                                               1');
        tempFile.Write('0000010010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 006290004614187 EUR0BE                  0000000292458810090107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000KTTEA0CTR DOMALGDOV01100000000105784010010700501000110' +
          '7740784372894100107I=0701599551 R=36291539        01001070060100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000LEGLA0B5R DOMNINDIN01100000007880763010010700501000110' +
          '7740784719367110107      060534695                01001070060100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8006290004614187 EUR0BE                  0000000212593340100107 ' +
          '                                                                ');
        tempFile.Write('9               000008000000079865470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000011010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 007290004614187 EUR0BE                  0000000212593340100107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000LJEHA0APR DOMALGDOV01100000000028146011010700501000110' +
          '774071599264511010773518-LF-0  2536630   413794   01101070070100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000LJEHA0APS DOMALGDOV01100000000028702011010700501000110' +
          '774071599264511010773520-LF-0  2536631   413794   01101070070100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000LJEHA0APT DOMALGDOV01100000000033999011010700501000110' +
          '774071599264511010773521-LF-0  2536632   413794   01101070070100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('8007290004614187 EUR0BE                  0000000211684870110107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000000908470000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000012010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 008290004614187 EUR0BE                  0000000211684870110107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9464620JBBNEUBCRCL1000000002898250012010734150000000' +
          '352037012A3186                                     1201070081001');
        tempFile.Write('3100010001OL9464620JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9464620JBBNEUBCRCL13415000010026710280720000227 6324' +
          ' 6326                                                        0 0');
        tempFile.Write('2100010003OL9464620JBBNEUBCRCL1000000002898250012010784150100110' +
          '5000000028982500000000028982500000100000000EUR     1201070081100');
        tempFile.Write('2200010003         000000028982500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000MGLC00104BTBOGOVOVERS0000000000112530120107001500000  ' +
          '          6303                                     1201070080100');
        tempFile.Write('2300020000443900062197                         SANTENS NV       ' +
          '         GALGESTRAAT 157           9700 OUDENAARDE           000');
        tempFile.Write('8008290004614187 EUR0BE                  0000000240779900120107 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000000000000000029095030            ' +
          '                                                               1');
        tempFile.Write('0000015010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 009290004614187 EUR0BE                  0000000240779900120107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000MLMPA0AMU DOMALGDOV01100000000028712015010700501000110' +
          '774071599264515010778359-LF-0  2540014   413946   01501070090100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000MUUB02943LKKTOVSOVKUG100000000347147015010700319000112' +
          '45526145478490607    1431                          1501070090100');
        tempFile.Write('2300020000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8009290004614187 EUR0BE                  0000000237021310150107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000003758590000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 010290004614187 EUR0BE                  0000000237021310150107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NAIAA0AA0 DOMNINDIN01100000000001084016010700501000110' +
          '7740784719367170107      070031236                01601070100100');
        tempFile.Write('22000100000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100020000NKGU00273 TBOINDNLOON1000000000020010160107001010000EX' +
          'P TANKEN                                           1601070100100');
        tempFile.Write('2200020000                                                     D' +
          'IV6117                      000000000000000                  100');
        tempFile.Write('2300020000001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100030000NKGU00274 TBOINDNLOON1000000000136250160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200030000                                                     D' +
          'IV6118                      000000000000000                  100');
        tempFile.Write('2300030000737101218432                         VAN DE SYPE DAVID' +
          '         STATIONSSTR 124           9450 HAALTERT             000');
        tempFile.Write('2100040000NKGU00275 TBOINDNLOON1000000000092920160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200040000                                                     D' +
          'IV6119                      000000000000000                  100');
        tempFile.Write('2300040000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100050000NKGU00276 TBOINDNLOON1000000000093500160107001010000EX' +
          'P DEC06                                            1601070100100');
        tempFile.Write('2200050000                                                     D' +
          'IV6120                      000000000000000                  100');
        tempFile.Write('2300050000733163053996                         VERMEER PAUL     ' +
          '         TEN OTTER 80              2980 ZOERSEL              000');
        tempFile.Write('2100060000NKGU00277 TBOINDNLOON1000000000116800160107001010000EX' +
          'P JAN07                                            1601070100100');
        tempFile.Write('2200060000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300060000737005116185                         ISABELLE VAN DER ' +
          'PLAETSEN VARENDRIESKOUTER 4        9031 DRONGEN              000');
        tempFile.Write('8010290004614187 EUR0BE                  0000000236550990160107 ' +
          '                                                                ');
        tempFile.Write('9               000020000000000470320000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000017010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 011290004614187 EUR0BE                  0000000236550990160107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000NOEOA0BUR DOMDCDDID01100000000002804017010700501000110' +
          '7740745036768180107F. 2007040813 DOMICIL.         01701070110100');
        tempFile.Write('22000100000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('2100020000NRGD00175 TBOINDNLOON1000000004537500170107001010000FA' +
          'CT 27019                                           1701070110100');
        tempFile.Write('2200020000                                                     6' +
          '1778                        000000000000000                  100');
        tempFile.Write('2300020000738609290061                         ASTRA TEC BVBA   ' +
          '         INDUSTRIELAAN 19          8810 LICHTERVELDE         000');
        tempFile.Write('2100030000NRGD00176 TBOINDNLOON1000000005313300170107001010000IN' +
          'V6205 MIN VOORSCHOT MIN TEVEEL GEST                1701070110100');
        tempFile.Write('2200030000                                                     6' +
          '1957 MI                     000000000000000                  100');
        tempFile.Write('2300030000390031747246                         IPL              ' +
          '                                                             000');
        tempFile.Write('21000400007409A3BWQ KGDTTNTERNG1000000004000000160107009010000  ' +
          '                                                   1701070110000');
        tempFile.Write('8011290004614187 EUR0BE                  0000000222672150170107 ' +
          '                                                                ');
        tempFile.Write('9               000012000000013878840000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000018010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 012290004614187 EUR0BE                  0000000222672150170107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OCGP00069BTBOGOVOVERS000000000122210018010700150000063' +
          '13;                                                1801070120100');
        tempFile.Write('2300010000443900193149                         C-MAC ELECTROMAG ' +
          'N.V.     INDUSTRIEZONE 28          9600 RONSE                000');
        tempFile.Write('8012290004614187 EUR0BE                  0000000223894250180107 ' +
          '                                                                ');
        tempFile.Write('9               000004000000000000000000000001222100            ' +
          '                                                               1');
        tempFile.Write('0000019010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 013290004614187 EUR0BE                  0000000223894250180107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OOQXA0AAO DOMNINDIN01100000000099810019010700501000110' +
          '7740784398863220107               0070140918      01901070130100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000OQEJ02375 TBOINDNLOON1000000003700000190107001010000FA' +
          'CTUUR F20060264                                    1901070130100');
        tempFile.Write('2200020000                                                     6' +
          '1961                        000000000000000                  100');
        tempFile.Write('2300020000447962409164                         DE GOUDEN KROON  ' +
          '         MARKTPLEIN 3-9            9940 EVERGEM              000');
        tempFile.Write('2100030000OQEJ02376 TBOINDNLOON10000000116142301901070010100002 ' +
          'AF MIN 2 VF MIN TEV BET                            1901070130100');
        tempFile.Write('2200030000                                                     7' +
          '0048 59                     000000000000000                  100');
        tempFile.Write('2300030000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100040000OL9414457JBBNEUBCRCL1000000000738811019010734150000000' +
          '352037019A2387                                     1901070131001');
        tempFile.Write('3100040001OL9414457JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200040001BUILDING AA                                           ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9414457JBBNEUBCRCL13415000010026710280720000287 6327' +
          '                                                             0 0');
        tempFile.Write('2100040003OL9414457JBBNEUBCRCL1000000000738811019010784150100110' +
          '5000000007388110000000007388110000100000000EUR     1901070131100');
        tempFile.Write('2200040003         000000007388110                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000OTJZ07706BOVSBBNONTVA0000000006470000190107001500000IN' +
          'VOICE 6227                                         1901070130100');
        tempFile.Write('2300050000293047693339                         NV PELEMAN INDUST' +
          'RIES     RIJKSWEG 7                2870    PUURS             000');
        tempFile.Write('8013290004614187 EUR0BE                  0000000221440030190107 ' +
          '                                                                ');
        tempFile.Write('9               000019000000016312330000000013858110            ' +
          '                                                               1');
        tempFile.Write('0000022010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 014290004614187 EUR0BE                  0000000221440030190107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PERF03204 TBOINDNLOON1000000000260000220107001010000IN' +
          'SCHRIJVING LED EUROPE                              2201070140100');
        tempFile.Write('2200010000                                                     D' +
          'IV6108                      000000000000000                  100');
        tempFile.Write('2300010000091013155653                         BAO              ' +
          '         GABRIELLE PETITSTRAAT 4B121080 BRUSSEL 8            000');
        tempFile.Write('8014290004614187 EUR0BE                  0000000221180030220107 ' +
          '                                                                ');
        tempFile.Write('9               000005000000000260000000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000023010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 015290004614187 EUR0BE                  0000000221180030220107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000PQJJA0AM3 DOMALGDOV01100000000039663023010700501000110' +
          '774071599264523010775560-LF-0  2548125   414271   02301070150100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000PRFQ01851BTBOINDNLOON0000000000354000230107001500000FA' +
          'KT 7008    17/01/07   OUD IJZER                    2301070150100');
        tempFile.Write('2300020000449461774136                         DEKEUKELEIRE G & ' +
          'F BVBA   KOOPVAARDIJLAAN 49        9000  GENT                000');
        tempFile.Write('8015290004614187 EUR0BE                  0000000221137400230107 ' +
          '                                                                ');
        tempFile.Write('9               000007000000000396630000000000354000            ' +
          '                                                               1');
        tempFile.Write('0000025010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 016290004614187 EUR0BE                  0000000221137400240107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000QPGEA0B06 DOMALGDOV01100000000117504025010700501000110' +
          '7740784372894250107I=0701631865 R=37005468        02501070160100');
        tempFile.Write('22000100000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100020000QYVWA0ACA DOMNINDIN01100000000000456025010700501000110' +
          '7740784719367260107      070042466                02501070160100');
        tempFile.Write('22000200000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100030000QYVWA0ACB DOMNINDIN01100000002232500025010700501000110' +
          '7740784719367260107      060534697                02501070160100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8016290004614187 EUR0BE                  0000000197632800250107 ' +
          '                                                                ');
        tempFile.Write('9               000011000000023504600000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000026010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 017290004614187 EUR0BE                  0000000197632800250107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9456866JBBNEUNCRCL1000000010144318026010734150000000' +
          '352037026A2463                                     2601070171001');
        tempFile.Write('3100010001OL9456866JBBNEUNCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200010001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9456866JBBNEUNCRCL13415000010026710280720000415 6235' +
          ' 6274 6310                                                   0 0');
        tempFile.Write('2100010003OL9456866JBBNEUNCRCL1000000010144318026010784150100110' +
          '5000000101443180000000101443180000100000000EUR     2601070171100');
        tempFile.Write('2200010003         000000101443180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100020000OL9456867KBBNKOSDIVKS100000000001089026010734137000000' +
          '352037026A2463                                     2601070171000');
        tempFile.Write('2100020001OL9456867KBBNKOSDIVKS1000000000009000260107841370130  ' +
          '                                                   2601070170000');
        tempFile.Write('2100020002OL9456867KBBNKOSDIVKS100000000000189026010784137011110' +
          '6000000000001890000000000009000002100000000200000002601070171100');
        tempFile.Write('220002000200001890                                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9460898JBBOEUBCRECL000000001575055029010734150000000' +
          '352037026A6016                                     2601070171100');
        tempFile.Write('2200030000                                                     T' +
          '47A70124AD86                000000000000000                  001');
        tempFile.Write('3100030001OL9460898JBBOEUBCRECL341500001001STECA BATTERIELADESYS' +
          'TEME UND      PRAEZISIONSELEKTRONIK GMBH                     1 0');
        tempFile.Write('3200030001MAMMOSTRASSE 1                     87700 MEMMINGEN    ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9460898JBBOEUBCRECL341500001002INV. 6347 / 27.12.200' +
          '6             INV. 6336 - 6339 VOM 22.12.2006                0 0');
        tempFile.Write('2100030003OL9460898JBBOEUBCRECL000000001575055029010784150100110' +
          '5000000015750550000000015750550000100000000EUR     2601070171100');
        tempFile.Write('2200030003         000000015750550                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100040000OL7079304 KGDBDCVBDEG1000000000470390250107309050000Uw' +
          ' bestelling                      34118493343       2601070171000');
    end;

    local procedure WriteCODA1MultipleC(var tempFile: File)
    begin
        tempFile.Write('2100040001OL7079304 KGDBDCVBDEG100000000047039025010780905100110' +
          '5000000000470390000000000470390000063777500GBP     2601070171100');
        tempFile.Write('2200040001         000000000470390                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100050000RIQX00752BTBOINDNLOON0000000000224760260107001500000FA' +
          'CT. 6287                                           2601070170100');
        tempFile.Write('2300050000443900270143                         PRINTED CARPETS V' +
          'E.DE.BE. IND.PARK KL FRANKRIJK 62  9600  RONSE               000');
        tempFile.Write('8017290004614187 EUR0BE                  0000000314570010260107 ' +
          '                                                                ');
        tempFile.Write('9               000024000000000481280000000117418490            ' +
          '                                                               1');
        tempFile.Write('0000029010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 018290004614187 EUR0BE                  0000000314570010260107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000RUIXA0AMU DOMALGDOV01100000000036048029010700501000110' +
          '774071599264529010774337-LF-0  2557333   414652   02901070180100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000RVQH03264 TBOINDNLOON100000000001800029010700101000110' +
          '1079934278829                                      2901070180100');
        tempFile.Write('2200020000                                                     D' +
          'IV7002                      000000000000000                  100');
        tempFile.Write('2300020000390044242058                         VORMETAL O W-VLAA' +
          'NDEREN   TRAMSTRAAT 61             9052 ZWIJNAARDE           000');
        tempFile.Write('2100030000RVQH03265 TBOINDNLOON100000000139379029010700101000110' +
          '1000043806412                                      2901070180100');
        tempFile.Write('2200030000                                                     6' +
          '/1933                       000000000000000                  100');
        tempFile.Write('2300030000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100040000SABYA0A4M DOMNINDIN01100000000034704029010700501000110' +
          '774076656127030010753220361 30/01                 02901070180100');
        tempFile.Write('22000400000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100050000OL9410136IUBOEUBTRFCS100000000019559026010734101000000' +
          '352037029B9459                                     2901070181100');
        tempFile.Write('2200050000                                                     7' +
          '0095                        000000000000000                  001');
        tempFile.Write('3100050001OL9410136IUBOEUBTRFCS341010001001PACK FEINDRAHTE      ' +
          '              AM BAUWEG 9-11                                 1 0');
        tempFile.Write('320005000151645 GUMMERSBACH DE               DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100050002OL9410136IUBOEUBTRFCS341010001002RECHNUNG7500167      ' +
          '                                                             0 1');
        tempFile.Write('3100050003OL9410136IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100050004OL9410136IUBOEUBTRFCS100000000019559026010784101100110' +
          '5000000000195590000000000195590000100000000EUR     2901070181100');
        tempFile.Write('2200050004         000000000195590                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8018290004614187 EUR0BE                  0000000312255110290107 ' +
          '                                                                ');
        tempFile.Write('9               000022000000002314900000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000030010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 019290004614187 EUR0BE                  0000000312255110290107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000SPUG00352 TBOINDNLOON1000000013915000300107001010000FA' +
          'CT ST07001                                         3001070190100');
        tempFile.Write('2200010000                                                     7' +
          '0117                        000000000000000                  100');
        tempFile.Write('2300010000737016385868                         STEREYO          ' +
          '         ZONNESTR 7                9810 NAZARETH             000');
        tempFile.Write('2100020000SQOE00126 BHKDGLDTBLO1000000037058260300107101050000  ' +
          '                                                   3001070191000');
        tempFile.Write('2100020001SQNQ00001 TBOSOCOVERS1000000002050020300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020001449276421179                         KALFSVEL ALBERIK ' +
          '                                                             000');
        tempFile.Write('2100020002SQNQ00002 TBOSOCOVERS1000000003062420300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020002290019346063                         DE CLERCQ JOHN   ' +
          '                                                             000');
        tempFile.Write('2100020003SQNQ00003 TBOSOCOVERS1000000002262070300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020003001188642141                         DE BOODT SEBASTIA' +
          'AN                                                           000');
        tempFile.Write('2100020004SQNQ00004 TBOSOCOVERS1000000001567550300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020004780507355378                         VAN DEN BOSSCHE G' +
          'EERT                                                         000');
        tempFile.Write('2100020005SQNQ00005 TBOSOCOVERS1000000002047500300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020005979382731184                         ROMEYNS DIRK     ' +
          '                                                             000');
        tempFile.Write('2100020006SQNQ00006 TBOSOCOVERS1000000001875970300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020006777529118508                         VANDAMME PATRICK ' +
          '                                                             000');
        tempFile.Write('2100020007SQNQ00007 TBOSOCOVERS1000000001723310300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020007737446195801                         CANNOODT HENDRIK ' +
          '                                                             000');
        tempFile.Write('2100020008SQNQ00008 TBOSOCOVERS1000000001822980300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020008285032993567                         KIEKENS KRISTOF  ' +
          '                                                             000');
        tempFile.Write('2100020009SQNQ00009 TBOSOCOVERS1000000002295220300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020009738425378970                         DE MEERLEER GUIDO' +
          '                                                             000');
        tempFile.Write('2100020010SQNQ00010 TBOSOCOVERS1000000002553870300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020010290015438276                         GHIJSELEN JOZEF  ' +
          '                                                             000');
        tempFile.Write('2100020011SQNQ00011 TBOSOCOVERS1000000001721390300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020011001336470848                         VALLAEY MATTHIAS ' +
          '                                                             000');
        tempFile.Write('2100020012SQNQ00012 TBOSOCOVERS1000000001926210300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020012737101218432                         VAN DE SYPE DAVID' +
          '                                                             000');
        tempFile.Write('2100020013SQNQ00013 TBOSOCOVERS1000000001316770300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020013063952649462                         MOENS BRAM       ' +
          '                                                             000');
        tempFile.Write('2100020014SQNQ00014 TBOSOCOVERS1000000002086650300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020014293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100020015SQNQ00015 TBOSOCOVERS1000000001661660300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020015737005116185                         VAN DER PLAETSEN ' +
          'ISABELLE                                                     000');
        tempFile.Write('2100020016SQNQ00016 TBOSOCOVERS1000000001911840300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020016733163053996                         VERMEER PAUL     ' +
          '                                                             000');
        tempFile.Write('2100020017SQNQ00017 TBOSOCOVERS1000000001232440300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020017001347713047                         MINJAUW WOUTER   ' +
          '                                                             000');
        tempFile.Write('2100020018SQNQ00018 TBOSOCOVERS1000000001318760300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020018800226253891                         HERTOGE ANN      ' +
          '                                                             000');
        tempFile.Write('2100020019SQNQ00019 TBOSOCOVERS1000000001324090300107501050000/A' +
          '/ LONEN 01/2007                                    3001070190100');
        tempFile.Write('2300020019780539341736                         DE SAEDELEER SONJ' +
          'A                                                            000');
        tempFile.Write('2100020020SQNQ00020 TBOSOCOVERS1000000001297540300107501050000/A' +
          '/ LONEN 01/2007                                    3001070191100');
        tempFile.Write('2300020020063967633538                         COTTRELL ROY     ' +
          '                                                             000');
        tempFile.Write('8019290004614187 EUR0BE                  0000000261281850300107 ' +
          '                                                                ');
        tempFile.Write('9               000046000000050973260000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000031010729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 020290004614187 EUR0BE                  0000000261281850300107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TAAZA0D3Y IKLINNINNIG1000000000755750310107313410000  ' +
          '            INVESTERINGSKREDIET     726-3667975-97 3101070201000');
        tempFile.Write('2100010001TAAZA0D3Y IKLINNINNIG1000000000693670310107813410660  ' +
          '                                                   3101070200000');
        tempFile.Write('2100010002TAAZA0D3Y IKLINNINNIG1000000000062080310107813410020  ' +
          '                                                   3101070201000');
        tempFile.Write('2100020000TEBF03361 TBOINDNLOON1000000000147260310107001010000FA' +
          'CT 7006771RI                                       3101070200100');
        tempFile.Write('2200020000                                                     6' +
          '1818                        000000000000000                  100');
        tempFile.Write('2300020000230099456544                         ACAL             ' +
          '         LOZENBERG 4               1932 ZAVENTEM             000');
        tempFile.Write('2100030000TEBF03362 TBOINDNLOON1000000000417140310107001010000FA' +
          'CT870084                                           3101070200100');
        tempFile.Write('2200030000                                                     7' +
          '0014                        000000000000000                  100');
        tempFile.Write('2300030000444564625163                         ALLCOMM          ' +
          '         BRUSSelseSTEENWEG 424-426 9050 LEDEBERG (GENT       000');
        tempFile.Write('2100040000TEBF03363 TBOINDNLOON1000000002074860310107001010000FA' +
          'CT2500281402 1403 86009 86010                      3101070200100');
        tempFile.Write('2200040000                                                     6' +
          '1788 92                     000000000000000                  100');
        tempFile.Write('2300040000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100050000TEBF03364 TBOINDNLOON1000000000400380310107001010000IN' +
          'V284121 84120 84787                                3101070200100');
        tempFile.Write('2200050000                                                     6' +
          '1862 87                     000000000000000                  100');
        tempFile.Write('2300050000459250650182                         AVNET EUROPE NV  ' +
          '         KOUTERVELDSTRAAT 20       1831 DIEGEM               000');
        tempFile.Write('2100060000TEBF03365 TBOINDNLOON100000000015125031010700101000110' +
          '1571033615082                                      3101070200100');
        tempFile.Write('2200060000                                                     7' +
          '0053                        000000000000000                  100');
        tempFile.Write('2300060000000171003118                         BELGACOM         ' +
          '         K ALBERT II LAAN 27       1030 BRUSSEL 3            000');
        tempFile.Write('2100070000TEBF03366 TBOINDNLOON1000000000428540310107001010000FA' +
          'CT CF6 23848                                       3101070200100');
        tempFile.Write('2200070000                                                     6' +
          '1898                        000000000000000                  100');
        tempFile.Write('2300070000210033172032                         CEGELEC          ' +
          '         WOLUWELN 60               1200 BRUSSEL              000');
        tempFile.Write('2100080000TEBF03367 TBOINDNLOON100000000295773031010700101000016' +
          '4682 683 161505 161625                             3101070200100');
        tempFile.Write('2200080000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300080000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100090000TEBF03368 TBOINDNLOON1000000000108750310107001010000FA' +
          'CT2007 015                                         3101070200100');
        tempFile.Write('2200090000                                                     7' +
          '0046                        000000000000000                  100');
        tempFile.Write('2300090000068211139826                         CONFISERIE SYLVIE' +
          '         ANTOON CATRIESTRAAT 48    9031 DRONGEN              000');
        tempFile.Write('2100100000TEBF03369 TBOINDNLOON1000000000546320310107001010000FA' +
          'CT602540                                           3101070200100');
        tempFile.Write('2200100000                                                     6' +
          '1951                        000000000000000                  100');
        tempFile.Write('2300100000462912815161                         DECOSTERE        ' +
          '         BURCHTHOF 10-11           8580 AVELGEM              000');
        tempFile.Write('2100110000TEBF03370 TBOINDNLOON1000000000421610310107001010000FT' +
          ' BRU0929445                                        3101070200100');
        tempFile.Write('2200110000                                                     6' +
          '1947                        000000000000000                  100');
        tempFile.Write('2300110000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100120000TEBF03371 TBOINDNLOON1000000000166910310107001010000FT' +
          ' BRU0915766                                        3101070200100');
        tempFile.Write('2200120000                                                     6' +
          '1873                        000000000000000                  100');
        tempFile.Write('2300120000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100130000TEBF03372 TBOINDNLOON1000000000068240310107001010000FT' +
          ' BRU0916695                                        3101070200100');
        tempFile.Write('2200130000                                                     6' +
          '1872                        000000000000000                  100');
        tempFile.Write('2300130000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100140000TEBF03373 TBOINDNLOON1000000002366570310107001010000FA' +
          'CT504859                                           3101070200100');
        tempFile.Write('2200140000                                                     6' +
          '1840                        000000000000000                  100');
        tempFile.Write('2300140000414002661169                         EUROPRINT        ' +
          '         ZANDVOORTSTRAAT 21        2800 MECHELEN             000');
        tempFile.Write('2100150000TEBF03374 TBOINDNLOON1000000010845780310107001010000CO' +
          'NS INV141                                          3101070200100');
        tempFile.Write('2200150000                                                     6' +
          '1771                        000000000000000                  100');
        tempFile.Write('2300150000720540538471                         FARNELL IN ONE   ' +
          '         RUE DE L''AEROPOSTALE 11   4460 GRACE-HOLLOGNE       000');
        tempFile.Write('2100160000TEBF03375 TBOINDNLOON100000000004937031010700101000110' +
          '1162033393150                                      3101070200100');
        tempFile.Write('2200160000                                                     7' +
          '0056                        000000000000000                  100');
        tempFile.Write('2300160000437750115182                         FACQ             ' +
          '         GANGSTR 20                1050 BRUSSEL 5            000');
        tempFile.Write('2100170000TEBF03376 TBOINDNLOON100000000030120031010700101000110' +
          '1612631487833                                      3101070200100');
        tempFile.Write('2200170000                                                     6' +
          '1880                        000000000000000                  100');
        tempFile.Write('2300170000437751190165                         REXEL            ' +
          '         RUE DE LA TECHNOLOGIE     1082 BRUXELLES            000');
        tempFile.Write('2100180000OL9453892IUBOEUBTRFCS100000000004356030010734101000000' +
          '352037031A1449                                     3101070201100');
        tempFile.Write('2200180000                                                     6' +
          '1914                        000000000000000                  001');
        tempFile.Write('3100180001OL9453892IUBOEUBTRFCS341010001001ERIKS BV             ' +
          '              TOERMALIJNSTRAAT 5                             1 0');
        tempFile.Write('32001800011800BK ALKMAAR NL                  NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100180002OL9453892IUBOEUBTRFCS341010001002FACT9101877291       ' +
          '                                                             0 1');
        tempFile.Write('3100180003OL9453892IUBOEUBTRFCS341010001004RABOBANK NEDERLAND   ' +
          '                                                             0 0');
        tempFile.Write('2100180004OL9453892IUBOEUBTRFCS100000000004356030010784101100110' +
          '5000000000043560000000000043560000100000000EUR     3101070201100');
        tempFile.Write('2200180004         000000000043560                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100190000OL9453893IUBOEUBTRFCS100000000241410030010734101000000' +
          '352037031A1448                                     3101070201100');
        tempFile.Write('2200190000                                                     6' +
          '1938 939                    000000000000000                  001');
        tempFile.Write('3100190001OL9453893IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320019000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100190002OL9453893IUBOEUBTRFCS341010001002INV93954 93946       ' +
          '                                                             0 1');
        tempFile.Write('3100190003OL9453893IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100190004OL9453893IUBOEUBTRFCS100000000241410030010784101100110' +
          '5000000002414100000000002414100000100000000EUR     3101070201100');
        tempFile.Write('2200190004         000000002414100                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100200000OL9453894IUBOEUBTRFCS100000000015780030010734101000000' +
          '352037031A1450                                     3101070201001');
        tempFile.Write('3100200001OL9453894IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002000017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100200002OL9453894IUBOEUBTRFCS341010001002INV22025799 2204     ' +
          '                                                             0 1');
        tempFile.Write('3100200003OL9453894IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100200004OL9453894IUBOEUBTRFCS100000000015780030010784101100110' +
          '5000000000157800000000000157800000100000000EUR     3101070201100');
        tempFile.Write('2200200004         000000000157800                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8020290004614187 EUR0BE                  0000000236458730310107 ' +
          '                                                                ');
        tempFile.Write('9               000076000000024823120000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000001020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 021290004614187 EUR0BE                  0000000236458730310107' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000TQTKA0M00 DOMNINDIN01100000000034704031010700501000110' +
          '774076656127001020753220361 01/02                 00102070210100');
        tempFile.Write('22000100000000008314                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC-VERZEKERINGEN' +
          '                                                             000');
        tempFile.Write('2100020000TXJT00179 TBOINDNLOON100000000010600001020700101000037' +
          '933 730678                                         0102070210100');
        tempFile.Write('2200020000                                                     7' +
          '0019                        000000000000000                  100');
        tempFile.Write('2300020000723540244980                         JEVEKA BV        ' +
          '                                                             000');
        tempFile.Write('2100030000TXJT00180 TBOINDNLOON100000000009062001020700101000110' +
          '1206195491314                                      0102070210100');
        tempFile.Write('2200030000                                                     6' +
          '1940                        000000000000000                  100');
        tempFile.Write('2300030000340013762419                         LYRECO           ' +
          '         RUE DE CHENEE 53          4031 ANGLEUR              000');
        tempFile.Write('2100040000TXJT00181 TBOINDNLOON1000000000072600010207001010000FA' +
          'CT7235 7236                                        0102070210100');
        tempFile.Write('2200040000                                                     6' +
          '1888 89                     000000000000000                  100');
        tempFile.Write('2300040000000003149567                         MATEDEX          ' +
          '         AVENUE DE L''ARTISANAT 4   1420 BRAINE-L''ALLEU       000');
        tempFile.Write('2100050000TXJT00182 TBOINDNLOON1000000000343820010207001010000FA' +
          'CT60234                                            0102070210100');
        tempFile.Write('2200050000                                                     6' +
          '1926                        000000000000000                  100');
        tempFile.Write('2300050000271004538218                         NITRON NV        ' +
          '         RUE DE LA MAITRISE 2      1400 MONSTREUX            000');
        tempFile.Write('2100060000TXJT00183 TBOINDNLOON1000000000253160010207001010000FA' +
          'CT4100072921                                       0102070210100');
        tempFile.Write('2200060000                                                     6' +
          '1868                        000000000000000                  100');
        tempFile.Write('2300060000405012480190                         OTTO WOLFF NV    ' +
          '         DELLINGSTRAAT 57          2800 MECHELEN             000');
        tempFile.Write('2100070000TXJT00184 TBOINDNLOON1000000000433710010207001010000FA' +
          'CT 26105980 KLANT 3160                             0102070210100');
        tempFile.Write('2200070000                                                     6' +
          '1715                        000000000000000                  100');
        tempFile.Write('2300070000320032338254                         PEPPERL+ FUCHS NV' +
          '         METROPOOLSTRAAT 11        2900 SCHOTEN              000');
        tempFile.Write('2100080000TXJT00185 TBOINDNLOON1000000001252920010207001010000NO' +
          'TA1566700309                                       0102070210100');
        tempFile.Write('2200080000                                                     7' +
          '0009                        000000000000000                  100');
        tempFile.Write('2300080000001308220408                         ROMBAUT  C       ' +
          '         JAGERSSTR 20 BUS 9        2140 BORGERHOUT (AN       000');
        tempFile.Write('2100090000TXJT00186 TBOINDNLOON1000000007062250010207001010000DI' +
          'V INV                                              0102070210100');
        tempFile.Write('2200090000                                                     D' +
          'IV INV                      000000000000000                  100');
        tempFile.Write('2300090000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100100000TXJT00187 TBOINDNLOON1000000000977170010207001010000IN' +
          'V9168630 8632 8645 9288                            0102070210100');
        tempFile.Write('2200100000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300100000310000321503                         SPOERLE          ' +
          '         MINERVASTRAAT 14B2        1930 ZAVENTEM             000');
        tempFile.Write('2100110000TXJT00188 TBOINDNLOON1000000004118200010207001010000FA' +
          'CT10052711 712 713 714 52772                       0102070210100');
        tempFile.Write('2200110000                                                     D' +
          'IV                          000000000000000                  100');
        tempFile.Write('2300110000472302320181                         TEAM             ' +
          '         JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100120000TXJT00189 TBOINDNLOON1000000000166830010207001010000IN' +
          'V680908 670323                                     0102070210100');
        tempFile.Write('2200120000                                                     6' +
          '1937 70                     000000000000000                  100');
        tempFile.Write('2300120000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100130000TXJT00190 TBOINDNLOON1000000000251680010207001010000FA' +
          'CT2006 514                                         0102070210100');
        tempFile.Write('2200130000                                                     6' +
          '1879                        000000000000000                  100');
        tempFile.Write('2300130000380020603881                         VANGO PRINTING   ' +
          '         HIJFTESTRAAT 55           9080 LOCHRISTI            000');
        tempFile.Write('2100140000UGRD00495BTBOGOVOVERS000000005844663001020700150000063' +
          '32 6334                                            0102070210100');
        tempFile.Write('2300140000482901003155                         BEKAERT COORDINAT' +
          'IECENTRUMBEKAERTSTRAAT 2           8550 ZWEVEGEM             000');
        tempFile.Write('8021290004614187 EUR0BE                  0000000279429360010207 ' +
          '                                                                ');
        tempFile.Write('9               000043000000015476000000000058446630            ' +
          '                                                               1');
        tempFile.Write('0000002020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 022290004614187 EUR0BE                  0000000279429360010207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('21000100007409A3C88 KGDTTNTERNG1000000005777620010207009010000  ' +
          '                                                   0202070220000');
        tempFile.Write('8022290004614187 EUR0BE                  0000000273651740020207 ' +
          '                                                                ');
        tempFile.Write('9               000003000000005777620000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000005020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 023290004614187 EUR0BE                  0000000273651740020207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VGCN03809 TBOINDNLOON100000000031052005020700101000110' +
          '1061135212219                                      0502070230100');
        tempFile.Write('2200010000                                                     D' +
          'IV7011                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('2100020000VGCN03810 TBOINDNLOON100000000095623005020700101000110' +
          '1061143082757                                      0502070230100');
        tempFile.Write('2200020000                                                     D' +
          'IV7012                      000000000000000                  100');
        tempFile.Write('2300020000679200231036                         BELASTINGEN      ' +
          '         AUTOS                     1000 BRUSSEL 1            000');
        tempFile.Write('8023290004614187 EUR0BE                  0000000272384990050207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001266750000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000006020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 024290004614187 EUR0BE                  0000000272384990050207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000VVXKA0CN4 IKLINNINNIG1000000003660120060207313410000  ' +
          '            INVESTERINGSKREDIET     726-3754303-95 0602070241000');
        tempFile.Write('2100010001VVXKA0CN4 IKLINNINNIG1000000003333330060207813410660  ' +
          '                                                   0602070240000');
        tempFile.Write('2100010002VVXKA0CN4 IKLINNINNIG1000000000326790060207813410020  ' +
          '                                                   0602070241000');
        tempFile.Write('2100020000OL7087022 KGDBDCVBDEG1000000000805180050207309050000Uw' +
          ' bestelling                      34110007257       0602070241000');
        tempFile.Write('2100020001OL7087022 KGDBDCVBDEG100000000080518005020780905100110' +
          '5000000000805180000000000805180000124195500USD     0602070241100');
        tempFile.Write('2200020001         000000000805180                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000OL9498991JBBNEUBCRCL1000000002381053007020734150000000' +
          '352037037B7942                                     0602070241001');
        tempFile.Write('3100030001OL9498991JBBNEUBCRCL1341500001001SPLASHPOWER LTD      ' +
          '              THE JEFFREYS BUILDING, COWLEY RD               1 0');
        tempFile.Write('3200030001CAMBRIDGE CB4 0WS                                     ' +
          '                                                             0 1');
        tempFile.Write('3100030002OL9498991JBBNEUBCRCL1341500001002INV 6346             ' +
          '                                                             0 0');
        tempFile.Write('2100030003OL9498991JBBNEUBCRCL1000000002381053007020784150100110' +
          '5000000023810530000000023810530000100000000EUR     0602070241100');
        tempFile.Write('2200030003         000000023810530                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8024290004614187 EUR0BE                  0000000291730220060207 ' +
          '                                                                ');
        tempFile.Write('9               000014000000004465300000000023810530            ' +
          '                                                               1');
        tempFile.Write('0000007020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
    end;

    local procedure WriteCODA1MultipleD(var tempFile: File)
    begin
        tempFile.Write('1 025290004614187 EUR0BE                  0000000291730220060207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000OL9407316JBBOEUBCRECL000000000740800008020734150000000' +
          '352037038A1971                                     0702070251100');
        tempFile.Write('2200010000                                                     4' +
          '550-70360575928             000000000000000                  001');
        tempFile.Write('3100010001OL9407316JBBOEUBCRECL341500001001ROSTI POLSKA SP. Z.O.' +
          'O.            Elewatorska 29                                 1 0');
        tempFile.Write('320001000115-620  Bia ystok                                     ' +
          '                                                             0 1');
        tempFile.Write('3100010002OL9407316JBBOEUBCRECL341500001002INVOICE  7003        ' +
          '              SUROWIEC                                       0 0');
        tempFile.Write('2100010003OL9407316JBBOEUBCRECL000000000740800008020784150100110' +
          '5000000007408000000000007408000000100000000EUR     0702070251100');
        tempFile.Write('2200010003         000000007408000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8025290004614187 EUR0BE                  0000000299138220070207 ' +
          '                                                                ');
        tempFile.Write('9               000009000000000000000000000007408000            ' +
          '                                                               1');
        tempFile.Write('0000008020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 026290004614187 EUR0BE                  0000000299138220070207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XASOA0AM2 DOMALGDOV01100000000070164008020700501000110' +
          '774071599264508020774422-LF-0  2569189   415130   00802070260100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000XBRY02063 TBOINDNLOON1000000009292560080207001010000FA' +
          'CT20061767 FACT20061768 MIN 2 CN                   0802070260100');
        tempFile.Write('2200020000                                                     6' +
          '1838 61                     000000000000000                  100');
        tempFile.Write('2300020000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100030000XBRY02064 TBOINDNLOON1000000003523520080207001010000FA' +
          'CT60317                                            0802070260100');
        tempFile.Write('2200030000                                                     6' +
          '1844                        000000000000000                  100');
        tempFile.Write('2300030000733028656658                         VAN VOXDALE      ' +
          '         LANGE WINKELHAAKSTRAAT 26 2060 BERCHEM (ANTW.       000');
        tempFile.Write('2100040000OL9432203IUBOEUBTRFCS100000000700000007020734101000000' +
          '352037039A1708                                     0802070261100');
        tempFile.Write('2200040000                                                     7' +
          '0131                        000000000000000                  001');
        tempFile.Write('3100040001OL9432203IUBOEUBTRFCS341010001001NICHIA EUROPE BV     ' +
          '              HORNWEG 18                                     1 0');
        tempFile.Write('32000400011045 AR AMSTERDAM NL               NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100040002OL9432203IUBOEUBTRFCS341010001002INVOICE 20070248     ' +
          '                                                             0 1');
        tempFile.Write('3100040003OL9432203IUBOEUBTRFCS341010001004BANK OF TOKYO - MITSU' +
          'BISHI UFJ (HOL                                               0 0');
        tempFile.Write('2100040004OL9432203IUBOEUBTRFCS100000000700000007020784101100110' +
          '5000000007000000000000007000000000100000000EUR     0802070261100');
        tempFile.Write('2200040004         000000007000000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8026290004614187 EUR0BE                  0000000278620500080207 ' +
          '                                                                ');
        tempFile.Write('9               000019000000020517720000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000009020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 027290004614187 EUR0BE                  0000000278620500080207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000XNQXA0BCT IKLINNINNIG1000000000991820090207313410000  ' +
          '            INVESTERINGSKREDIET     726-2764912-07 0902070271000');
        tempFile.Write('2100010001XNQXA0BCT IKLINNINNIG1000000000950930090207813410660  ' +
          '                                                   0902070270000');
        tempFile.Write('2100010002XNQXA0BCT IKLINNINNIG1000000000040890090207813410020  ' +
          '                                                   0902070271000');
        tempFile.Write('2100020000OL9459477JBBNEUBCRCL1000000003540602009020734150000000' +
          '352037040A2319                                     0902070271001');
        tempFile.Write('3100020001OL9459477JBBNEUBCRCL1341500001001PHILIPS LIGHTING BV  ' +
          '              P.O. BOX 1                                     1 0');
        tempFile.Write('3200020001BUILDING AA                        OSS                ' +
          '                                                             0 1');
        tempFile.Write('3100020002OL9459477JBBNEUBCRCL13415000010026710280720000573 6308' +
          ' 6323 6342                                                   0 0');
        tempFile.Write('2100020003OL9459477JBBNEUBCRCL1000000003540602009020784150100110' +
          '5000000035406020000000035406020000100000000EUR     0902070271100');
        tempFile.Write('2200020003         000000035406020                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100030000XXNGA0B1O DOMNINDIN01100000000016858009020700501000110' +
          '7740784719367120207      070042467                00902070270100');
        tempFile.Write('22000300000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('2100040000XXNGA0B1P DOMNINDIN01100000001610006009020700501000110' +
          '7740784719367120207      070042480                00902070270100');
        tempFile.Write('22000400000409823416                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         HULP DER PATROONS' +
          ' DOMICIL.                                                    000');
        tempFile.Write('8027290004614187 EUR0BE                  0000000296766060090207 ' +
          '                                                                ');
        tempFile.Write('9               000017000000017260460000000035406020            ' +
          '                                                               1');
        tempFile.Write('0000012020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 028290004614187 EUR0BE                  0000000296766060090207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YCTIA0APN DOMALGDOV01100000000028146012020700501000110' +
          '774071599264512020773518-LF-0  2573027   415350   01202070280100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000YCTIA0APO DOMALGDOV01100000000028702012020700501000110' +
          '774071599264512020773520-LF-0  2573028   415350   01202070280100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YCTIA0APP DOMALGDOV01100000000033999012020700501000110' +
          '774071599264512020773521-LF-0  2573029   415350   01202070280100');
        tempFile.Write('22000300000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100040000YCUGA0CVW DOMALGDOV01100000000138109012020700501000110' +
          '7740784372894120207I=0701668378 R=37017803        01202070280100');
        tempFile.Write('22000400000403063902                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300040000000000000000                         NV TOTAL BELGIUM ' +
          'SA                                                           000');
        tempFile.Write('2100050000YGQM02428LKKTOVSOVKUG100000000499090012020700319000112' +
          '45526145478490607    1435                          1202070280100');
        tempFile.Write('2300050000666000000483                                          ' +
          '                                                             000');
        tempFile.Write('8028290004614187 EUR0BE                  0000000289485600120207 ' +
          '                                                                ');
        tempFile.Write('9               000016000000007280460000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000013020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 029290004614187 EUR0BE                  0000000289485600120207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000YPQM05627BOVSBBNONTVA000000000007026013020700150000017' +
          '01212007001422 6088 6088CN 632   9                 1302070290100');
        tempFile.Write('2300010000685668801833                         PHILIPS INNOVATIV' +
          'E APPLICATSTEENWEG OP GIERLE 417           TURNHOUT          000');
        tempFile.Write('2100020000YQCBA0AMJ DOMALGDOV01100000000028712013020700501000110' +
          '774071599264513020778359-LF-0  2576022   415418   01302070290100');
        tempFile.Write('22000200000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100030000YUPBA0E2M DOMUCVDIU01100000000002045013020700501000110' +
          '7740784397045130207227764/68145298                01302070290100');
        tempFile.Write('22000300000000938128                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300030000000000000000                         TAXIPOST         ' +
          '                                                             000');
        tempFile.Write('8029290004614187 EUR0BE                  0000000289248290130207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000000307570000000000070260            ' +
          '                                                               1');
        tempFile.Write('0000014020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 030290004614187 EUR0BE                  0000000289248290130207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000ZFFP02090 TBOINDNLOON100000000072659014020700101000110' +
          '1061222384503                                      1402070300100');
        tempFile.Write('2200010000                                                     D' +
          'IV7019                      000000000000000                  100');
        tempFile.Write('2300010000679200231036                         BELASTINGEN AUTOS' +
          '         KON ALBERT II LAAN        1030 BRUSSEL 3            000');
        tempFile.Write('2100020000ZFFP02091 TBOINDNLOON1000000008558820140207001010000FA' +
          'CT 1491                                            1402070300100');
        tempFile.Write('2200020000                                                     7' +
          '0198                        000000000000000                  100');
        tempFile.Write('2300020000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('2100030000ZFFP02092 TBOINDNLOON1000000000035000140207001010000/A' +
          '/ EXP NOV DEC JAN                                  1402070300100');
        tempFile.Write('2200030000                                                     D' +
          'IV7013                      000000000000000                  100');
        tempFile.Write('2300030000780507355378                         VANDENBOSSCHE GEE' +
          'RT                                                           000');
        tempFile.Write('2100040000ZFFP02093 TBOINDNLOON1000000000316180140207001010000/A' +
          '/ EXP JAN07 HALT TUV                               1402070300100');
        tempFile.Write('2200040000                                                     D' +
          'IV7015                      000000000000000                  100');
        tempFile.Write('2300040000293016209361                         VAEL PHILIP      ' +
          '                                                             000');
        tempFile.Write('2100050000ZFFP02094 TBOINDNLOON1000000000028100140207001010000/A' +
          '/ EXP AANKOOP MACRO                                1402070300100');
        tempFile.Write('2200050000                                                     D' +
          'IV7016                      000000000000000                  100');
        tempFile.Write('2300050000979382731184                         ROMEYNS DIRK     ' +
          '         WAFELSTRAAT 26            9630 ZWALM                000');
        tempFile.Write('2100060000ZFFP02095 TBOINDNLOON1000000000020600140207001010000/A' +
          '/ EXP TREIN 080207                                 1402070300100');
        tempFile.Write('2200060000                                                     D' +
          'IV7020                      000000000000000                  100');
        tempFile.Write('2300060000001347713047                         WOUTER MINJAUW   ' +
          '         DENTERGEMSTRAAT 67        8780 OOSTROZEBEKE         000');
        tempFile.Write('2100070000ZFFP02096 TBOINDNLOON1000000000285200140207001010000/A' +
          '/ EXP SPLASH JAN FEB 07                            1402070300100');
        tempFile.Write('2200070000                                                     D' +
          'IV7022                      000000000000000                  100');
        tempFile.Write('2300070000290019346063                         DE CLERCQ JOHN   ' +
          '         BLEKTE 81                 9340 LEDE                 000');
        tempFile.Write('2100080000ZFFP02097 TBOINDNLOON100000000001050014020700101000110' +
          '1000060345518                                      1402070300100');
        tempFile.Write('2200080000                                                     D' +
          'IV7017                      000000000000000                  100');
        tempFile.Write('2300080000679205479140                         VOLMACHTEN       ' +
          '         MUNTCENTRUM               1000 BRUSSEL 1            000');
        tempFile.Write('2100090000ZFFP02098 TBOINDNLOON1000000015028010140207001010000FA' +
          'CT1865 1866 1867                                   1402070300100');
        tempFile.Write('2200090000                                                     6' +
          '1943 44                     000000000000000                  100');
        tempFile.Write('2300090000230056163828                         TRINSY TECHNICS  ' +
          '         ANTWERPSESTWG 120         2390 MALLE                000');
        tempFile.Write('2100100000ZFFP02099 TBOINDNLOON1000000000037080140207001010000FA' +
          'CT 111700303 112600758                             1402070300100');
        tempFile.Write('2200100000                                                     6' +
          '1916 70                     000000000000000                  100');
        tempFile.Write('2300100000290028356050                         BUYSSE WILLEMS GA' +
          'RAGE     JACQUES PARIJSLAAN 8      9940 EVERGEM              000');
        tempFile.Write('2100110000ZFFP02100 TBOINDNLOON1000000003598200140207001010000DI' +
          'V INV                                              1402070300100');
        tempFile.Write('2200110000                                                     6' +
          '1805 83                     000000000000000                  100');
        tempFile.Write('2300110000825601531087                         RUTRONIK         ' +
          '         INDUSTRIESTRASSE 2        7522 ISPRINGEN            000');
        tempFile.Write('2100120000ZFFP02101 TBOINDNLOON1000000000176620140207001010000FA' +
          'CT 576488 KL 014347                                1402070300100');
        tempFile.Write('2200120000                                                     6' +
          '1927                        000000000000000                  100');
        tempFile.Write('2300120000444961820157                         HANSSENS HOUT NV ' +
          '         PORT ARTHURLAAN 90        9000 GENT                 000');
        tempFile.Write('2100130000ZFFP02102 TBOINDNLOON1000000000562650140207001010000FA' +
          'CT 171144 KLANT 12032                              1402070300100');
        tempFile.Write('2200130000                                                     7' +
          '0090                        000000000000000                  100');
        tempFile.Write('2300130000685616301086                         NV FLUKE BELGIUM ' +
          '         LANGEVELDPARK UNIT7       1600 ST-PIETERS-LEE       000');
        tempFile.Write('2100140000ZFFP02103 TBOINDNLOON1000000000285310140207001010000FA' +
          'CT 0180688                                         1402070300100');
        tempFile.Write('2200140000                                                     6' +
          '1866                        000000000000000                  100');
        tempFile.Write('2300140000459250790127                         BINPAC           ' +
          '         IZ OOST, VRIJHEIDWEG 8    3700 TONGEREN             000');
        tempFile.Write('2100150000ZFFP02104 TBOINDNLOON1000000002860150140207001010000FA' +
          'CT 165279 280 161772 161896                        1402070300100');
        tempFile.Write('2200150000                                                     7' +
          '0092 87                     000000000000000                  100');
        tempFile.Write('2300150000443900193149                         CMAC             ' +
          '         IZ KL FRANKRIJK 28        9600 RONSE                000');
        tempFile.Write('2100160000ZFFP02105 TBOINDNLOON1000000001499400140207001010000BR' +
          'U0948706                                           1402070300100');
        tempFile.Write('2200160000                                                     7' +
          '0143                        000000000000000                  100');
        tempFile.Write('2300160000482910700226                         DHL              ' +
          '         POSTBUS 31                1831 DIEGEM               000');
        tempFile.Write('2100170000ZFFP02106 TBOINDNLOON1000000000092930140207001010000FA' +
          'CT614BE00972                                       1402070300100');
        tempFile.Write('2200170000                                                     6' +
          '1816                        000000000000000                  100');
        tempFile.Write('2300170000230099418451                         SEMIKRON         ' +
          '         LEUVENSESTEENWEG 510B9    1930 ZAVENTEM             000');
        tempFile.Write('2100180000ZFFP02107 TBOINDNLOON1000000000367840140207001010000FA' +
          'CT 70061248                                        1402070300100');
        tempFile.Write('2200180000                                                     6' +
          '1617                        000000000000000                  100');
        tempFile.Write('2300180000737427040422                         INTERCARE        ' +
          '         KORTE MAGERSTR 5          9050 GENTBRUGGE           000');
        tempFile.Write('2100190000ZFFP02108 TBOINDNLOON1000000000105390140207001010000FA' +
          'CT6069815                                          1402070300100');
        tempFile.Write('2200190000                                                     6' +
          '1921                        000000000000000                  100');
        tempFile.Write('2300190000230030914021                         VINK             ' +
          '         INDUSTRIEPARK 7           2220 HEIST-OP-DEN-B       000');
        tempFile.Write('2100200000ZFFP02109 TBOINDNLOON1000000000271800140207001010000FA' +
          'CT687804 685187 689218 695010 702325               1402070300100');
        tempFile.Write('2200200000                                                     7' +
          '0078 17                     000000000000000                  100');
        tempFile.Write('2300200000210049670015                         TNT              ' +
          '                                                             000');
        tempFile.Write('2100210000ZFFP02110 TBOINDNLOON1000000000623390140207001010000FA' +
          'CT 260620                                          1402070300100');
        tempFile.Write('2200210000                                                     6' +
          '1953                        000000000000000                  100');
        tempFile.Write('2300210000293021332779                         NOTEBAERT        ' +
          '         AALSTSTRAAT 6             9700 OUDENAARDE           000');
        tempFile.Write('2100220000ZFFP02111 TBOINDNLOON1000000003530760140207001010000FA' +
          'CT 28016690S01028                                  1402070300100');
        tempFile.Write('2200220000                                                     6' +
          '1751                        000000000000000                  100');
        tempFile.Write('2300220000285020504213                         BARCO KUURNE     ' +
          '         NOORDLAAN 5               8520 KUURNE               000');
        tempFile.Write('2100230000ZFFP02112 TBOINDNLOON1000000001116250140207001010000FA' +
          'CT F06121401                                       1402070300100');
        tempFile.Write('2200230000                                                     6' +
          '1911                        000000000000000                  100');
        tempFile.Write('2300230000063991768047                         CPE              ' +
          '         SCHEURBOEK 6A             9860 OOSTERZELE           000');
        tempFile.Write('2100240000ZFFP02113 TBOINDNLOON1000000003254900140207001010000FA' +
          'CT 7241730                                         1402070300100');
        tempFile.Write('2200240000                                                     7' +
          '0021                        000000000000000                  100');
        tempFile.Write('2300240000419706600164                         ECOMAL           ' +
          '         BATTelseSTWG 455E         2800 MECHELEN             000');
        tempFile.Write('2100250000ZFFP02114 TBOINDNLOON1000000000320650140207001010000FA' +
          'CT 23830                                           1402070300100');
        tempFile.Write('2200250000                                                     6' +
          '1886                        000000000000000                  100');
        tempFile.Write('2300250000320050648420                         PCB              ' +
          '         ELLERMANSTRAAT 74         2060 ANTWERPEN 6          000');
        tempFile.Write('2100260000ZFFP02115 TBOINDNLOON100000000092889014020700101000110' +
          '1000043806513                                      1402070300100');
        tempFile.Write('2200260000                                                     7' +
          '0100                        000000000000000                  100');
        tempFile.Write('2300260000435411161155                         PROXIMUS         ' +
          '         VOORTUIGANGSTRAAT 55      1210 BRUSSEL 21           000');
        tempFile.Write('2100270000ZFFP02116 TBOINDNLOON1000000003820840140207001010000FA' +
          'CT 111605534                                       1402070300100');
        tempFile.Write('2200270000                                                     6' +
          '1884                        000000000000000                  100');
        tempFile.Write('2300270000737502090534                         VANHOONACKER OUDE' +
          'NAARDE   WESTERING 31              9700 OUDENAARDE           000');
        tempFile.Write('2100280000OL9449950IUBOEUBTRFCS100000000070000013020734101000000' +
          '352037045A1181                                     1402070301100');
        tempFile.Write('2200280000                                                     7' +
          '0028                        000000000000000                  001');
        tempFile.Write('3100280001OL9449950IUBOEUBTRFCS341010001001VOGHT ELECTRONIC COMP' +
          'ONENT         VOGHT ELECTR PLATZ 1                           1 0');
        tempFile.Write('320028000194130 OBERNZELL DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100280002OL9449950IUBOEUBTRFCS341010001002INV1038385           ' +
          '                                                             0 1');
        tempFile.Write('3100280003OL9449950IUBOEUBTRFCS341010001004COMMERZBANK AG       ' +
          '                                                             0 0');
        tempFile.Write('2100280004OL9449950IUBOEUBTRFCS100000000070000013020784101100110' +
          '5000000000700000000000000700000000100000000EUR     1402070301100');
        tempFile.Write('2200280004         000000000700000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100290000OL9449951IUBOEUBTRFCS100000000024216013020734101000000' +
          '352037045A1180                                     1402070301100');
        tempFile.Write('2200290000                                                     3' +
          'INV                         000000000000000                  001');
        tempFile.Write('3100290001OL9449951IUBOEUBTRFCS341010001001DIGI KEY CORPORATION ' +
          '              PO BOX 52                                      1 0');
        tempFile.Write('32002900017500AB ENSCHEDE NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100290002OL9449951IUBOEUBTRFCS341010001002INV22113733 2212     ' +
          '              3054 22123483                                  0 1');
        tempFile.Write('3100290003OL9449951IUBOEUBTRFCS341010001004LLOYDS TSB BANK PLC  ' +
          '                                                             0 0');
        tempFile.Write('2100290004OL9449951IUBOEUBTRFCS100000000024216013020784101100110' +
          '5000000000242160000000000242160000100000000EUR     1402070301100');
        tempFile.Write('2200290004         000000000242160                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100300000OL9449952IUBOEUBTRFCS100000000086000013020734101000000' +
          '352037045A1179                                     1402070301001');
        tempFile.Write('3100300001OL9449952IUBOEUBTRFCS341010001001BERGQUIST-ITC        ' +
          '              HADERSLEBENER STR. 19A                         1 0');
        tempFile.Write('320030000125421 PINNEBERG DE                 DE                 ' +
          '                                                             0 1');
        tempFile.Write('3100300002OL9449952IUBOEUBTRFCS341010001002INVOICE 94090        ' +
          '                                                             0 1');
        tempFile.Write('3100300003OL9449952IUBOEUBTRFCS341010001004DEUTSCHE BANK AG     ' +
          '                                                             0 0');
        tempFile.Write('2100300004OL9449952IUBOEUBTRFCS100000000086000013020784101100110' +
          '5000000000860000000000000860000000100000000EUR     1402070301100');
        tempFile.Write('2200300004         000000000860000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100310000OL9449953IUBOEUBTRFCS100000000008150013020734101000000' +
          '352037045A1178                                     1402070301100');
        tempFile.Write('2200310000                                                     D' +
          'IV7014                      000000000000000                  001');
        tempFile.Write('3100310001OL9449953IUBOEUBTRFCS341010001001ABONNEMENTENLAND     ' +
          '              POSTBUS 20                                     1 0');
        tempFile.Write('32003100011910AA UITGEEST NL                 NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100310002OL9449953IUBOEUBTRFCS341010001002FACTUUR 30370573     ' +
          '              KLANTNR 7682031                                0 1');
        tempFile.Write('3100310003OL9449953IUBOEUBTRFCS341010001004POSTBANK NV          ' +
          '                                                             0 0');
        tempFile.Write('2100310004OL9449953IUBOEUBTRFCS100000000008150013020784101100110' +
          '5000000000081500000000000081500000100000000EUR     1402070301100');
        tempFile.Write('2200310004         000000000081500                              ' +
          '                            000000000000000                  000');
        tempFile.Write('2100320000OL9449954IUBOEUBTRFCS100000000179300013020734101000000' +
          '352037045A1182                                     1402070301001');
        tempFile.Write('3100320001OL9449954IUBOEUBTRFCS341010001001ZUKEN BV             ' +
          '              SCHEPENLAAN 18A                                1 0');
        tempFile.Write('32003200016002EE WEERT NL                    NL                 ' +
          '                                                             0 1');
        tempFile.Write('3100320002OL9449954IUBOEUBTRFCS341010001002FACT ZNL100488       ' +
          '                                                             0 1');
        tempFile.Write('3100320003OL9449954IUBOEUBTRFCS341010001004ABN AMRO BANK NV     ' +
          '                                                             0 0');
        tempFile.Write('2100320004OL9449954IUBOEUBTRFCS100000000179300013020784101100110' +
          '5000000001793000000000001793000000100000000EUR     1402070301100');
        tempFile.Write('2200320004         000000001793000                              ' +
          '                            000000000000000                  000');
        tempFile.Write('8030290004614187 EUR0BE                  0000000237109580140207 ' +
          '                                                                ');
        tempFile.Write('9               000121000000052138710000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000016020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 031290004614187 EUR0BE                  0000000237109580150207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000AIBHA0AAN DOMNINDIN01100000000099810016020700501000110' +
          '7740784398863190207               0070142022      01602070310100');
        tempFile.Write('22000100000876383320                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         D''IETEREN SERVICE' +
          'S                                                            000');
        tempFile.Write('2100020000AUBOA0CH4 DOMDCDDID01100000000003740016020700501000110' +
          '7740745036768190207F. 2007065205 DOMICIL.         01602070310100');
        tempFile.Write('22000200000455530509                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300020000000000000000                         ISABEL           ' +
          '                                                             000');
        tempFile.Write('8031290004614187 EUR0BE                  0000000236074080160207 ' +
          '                                                                ');
        tempFile.Write('9               000008000000001035500000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000019020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 032290004614187 EUR0BE                  0000000236074080140207' +
          'INVERTO NV                KBC-Bedrijfsrekening               001');
        tempFile.Write('2100010000BJUA00109 TBOINDNLOON1000000001352480190207001010000ON' +
          'KOSTEN BELCOMP EN VDVIJVER                         1902070320100');
        tempFile.Write('2200010000                                                     D' +
          'IV ONKO                     000000000000000                  100');
        tempFile.Write('2300010000467538877123                         FIBECON BVBA     ' +
          '         MEERSBLOEM MELDEN 30      9700 OUDENAARDE           000');
        tempFile.Write('8032290004614187 EUR0BE                  0000000234721600190207 ' +
          '                                                                ');
        tempFile.Write('9               000005000000001352480000000000000000            ' +
          '                                                               1');
        tempFile.Write('0000020020729005D  0000000074789  INVERTO NV                0000' +
          '000000000058315707 00000                                       1');
        tempFile.Write('1 033290004614187 EUR0BE                  0000000234721600190207' +
          'INVERTO NV                KBC-Bedrijfsrekening               002');
        tempFile.Write('2100010000BNIVA0AMT DOMALGDOV01100000000039663020020700501000110' +
          '774071599264520020775560-LF-0  2584186   415775   02002070330100');
        tempFile.Write('22000100000426403684                                            ' +
          '                            000000000000000                  100');
        tempFile.Write('2300010000000000000000                         KBC LEASE BELGIUM' +
          '                                                             000');
        tempFile.Write('2100020000BOUJ01943 TBOINDNLOON100000001698636020020700101000110' +
          '1086444207901                                      2002070330100');
        tempFile.Write('2200020000                                                     A' +
          'ANSLJ 2                     000000000000000                  100');
        tempFile.Write('2300020000679200250133                         VENN BELAST      ' +
          '         G CROMMENLAAN 6 BUS 101   9050 LEDEBERG (GENT       000');
        tempFile.Write('2100030000BRLY08683BOVSBBNONTVA000000000030752020020700150000057' +
          '90131579 CREDITNOTA 010207                         2002070330100');
        tempFile.Write('2300030000000171003118                         Belgacom PO  NOOR' +
          'D        Stationsstraat, 58        2800 Mechelen             000');
        tempFile.Write('8033290004614187 EUR0BE                  0000000217646130200207 ' +
          '                                                                ');
        tempFile.Write('9               000010000000017382990000000000307520            ' +
          '                                                               2');
    end;

    local procedure WriteOnCODAScenario557240(var TempFile: File)
    begin
        TempFile.Write('0000016092430005        33610135  MY AMERICAN SHOP SRL      BBRUBEBB   00058315707 00000                                       2');
        TempFile.Write('12157BE75363216340251                  EUR0000000026688480150924MY AMERICAN SHOP SRL      Compte à vue                       157');
        TempFile.Write('2100010000CAL/F/1322404000639  1000000033671370160924030030000Mouvement lié à la transaction FXForward             16092415701 0');
        TempFile.Write('2200010000       - 33.671,37FXN71322404  (ING Trade : DI1242640                                                              1 0');
        TempFile.Write('2300010000                                                                        0P00106)                                   0 1');
        TempFile.Write('3100010001CAL/F/1322404000639  030030000Transaction FX Forward avec la référence 71322404 Conclue avec ING Belgiu            0 1');
        TempFile.Write('3100010002CAL/F/1322404000639  030030000m SA/NV le 16/09/2024 ING vous a acheté 33.671,37 EUR ING vous a vendu 37            0 1');
        TempFile.Write('3100010003CAL/F/1322404000639  030030000.400,00 USD Taux de change: 1,110736                                                 0 1');
        TempFile.Write('3100010004CAL/F/1322404000639  030030000MAMERICBAS                                                                           0 0');
        TempFile.Write('2100020000I160733008384000637  0000000009058060160924001500000YYW1036909217794/PAYPAL                              16092415701 0');
        TempFile.Write('2200020000                                                     YYW1036909217794                   PPLXLUL2                   1 0');
        TempFile.Write('2300020000LU89751000135104200E                 PayPal Europe S.a.r.l. et Cie S.C.A                                           0 1');
        TempFile.Write('3100020001I160733008384000637  001500001001PayPal Europe S.a.r.l. et Cie S.C.A                                               1 0');
        TempFile.Write('320002000122-24 Boulevard Royal, 2449 Luxembo                                                                                0 1');
        TempFile.Write('3100020002I160733008384000637  001500000Virement en euros (SEPA) De: PayPal Europe S.a.r.l. et Cie S.C.A 22-24 Bo            0 1');
        TempFile.Write('3100020003I160733008384000637  001500000ulevard Royal, 2449 Luxembourg Luxembourg IBAN: LU89751000135104200E Comm            0 1');
        TempFile.Write('3100020004I160733008384000637  001500000unication : YYW1036909217794/PAYPAL Info personnelle: YYW1036909217794               0 1');
        TempFile.Write('3100020005I160733008384000637  001500000Communication: YYW1036909217794/PAYPAL Info personnelle: YYW1036909217794            0 1');
        TempFile.Write('3100020006I160733008384000637  001500000                                                                                     0 0');
        TempFile.Write('2100030000I160918319904000640  0000000000018350160924001500000MYAMERICANSHOP                                       16092415701 0');
        TempFile.Write('2200030000                                                     MYAMERICA-MG1ZLB5GSYHFLPSAGKTRGPXDICITINL2X                   1 0');
        TempFile.Write('2300030000NL41CITI2032304805                   STRIPE                                                                        0 1');
        TempFile.Write('3100030001I160918319904000640  001500001001STRIPE                                                                            1 0');
        TempFile.Write('3200030001CO A L GOODBODY IFSC NORTH WALL QUA                                                                                0 1');
        TempFile.Write('3100030002I160918319904000640  001500000Virement en euros (SEPA) De: STRIPE CO A L GOODBODY IFSC NORTH WALL QUADU            0 1');
        TempFile.Write('3100030003I160918319904000640  001500000BLIN,DUBLIN 1,D01H104 Irlande (Eire) IBAN: NL41CITI2032304805 Communicati            0 1');
        TempFile.Write('3100030004I160918319904000640  001500000on : MYAMERICANSHOP Info personnelle: MYAMERICA-MG1ZLB5GSYHFLPSAGKTRGPXDI            0 1');
        TempFile.Write('3100030005I160918319904000640  001500000                                                                                     0 1');
        TempFile.Write('3100030006I160918319904000640  001500000Communication: MYAMERICANSHOP Info personnelle: MYAMERICA-MG1ZLB5GSYHFLPS            0 1');
        TempFile.Write('3100030007I160918319904000640  001500000AGKTRGPXDI                                                                           0 0');
        TempFile.Write('2100040000I161133458289000641  0000000017105830160924001500000REF T08123471.2409.11                                16092415701 0');
        TempFile.Write('2200040000                                                     T08123471.2409.11                  CITINL2X                   1 0');
        TempFile.Write('2300040000NL70CITI2032329018                   Stichting Mollie Payments                                                     0 1');
        TempFile.Write('3100040001I161133458289000641  001500001001Stichting Mollie Payments                                                         1 0');
        TempFile.Write('3200040001126Keizersgracht                   Amsterdam,1015 CW                                                               0 1');
        TempFile.Write('3100040002I161133458289000641  001500000Virement en euros (SEPA) De: Stichting Mollie Payments 126Keizersgracht A            0 1');
        TempFile.Write('3100040003I161133458289000641  001500000msterdam,1015 CW Pays-Bas IBAN: NL70CITI2032329018 Communication : REF T0            0 1');
        TempFile.Write('3100040004I161133458289000641  0015000008123471.2409.11 Info personnelle: T08123471.2409.11                                  0 1');
        TempFile.Write('3100040005I161133458289000641  001500000Communication: REF T08123471.2409.11 Info personnelle: T08123471.2409.11             0 1');
        TempFile.Write('3100040006I161133458289000641  001500000                                                                                     0 0');
        TempFile.Write('2100050000I161432508450000646  0000000006090410160924001500000YYW1036965172577/PAYPAL                              16092415701 0');
        TempFile.Write('2200050000                                                     YYW1036965172577                   PPLXLUL2                   1 0');
        TempFile.Write('2300050000LU89751000135104200E                 PayPal Europe S.a.r.l. et Cie S.C.A                                           0 1');
        TempFile.Write('3100050001I161432508450000646  001500001001PayPal Europe S.a.r.l. et Cie S.C.A                                               1 0');
        TempFile.Write('320005000122-24 Boulevard Royal, 2449 Luxembo                                                                                0 1');
        TempFile.Write('3100050002I161432508450000646  001500000Virement en euros (SEPA) De: PayPal Europe S.a.r.l. et Cie S.C.A 22-24 Bo            0 1');
        TempFile.Write('3100050003I161432508450000646  001500000ulevard Royal, 2449 Luxembourg Luxembourg IBAN: LU89751000135104200E Comm            0 1');
        TempFile.Write('3100050004I161432508450000646  001500000unication : YYW1036965172577/PAYPAL Info personnelle: YYW1036965172577               0 1');
        TempFile.Write('3100050005I161432508450000646  001500000Communication: YYW1036965172577/PAYPAL Info personnelle: YYW1036965172577            0 1');
        TempFile.Write('3100050006I161432508450000646  001500000                                                                                     0 0');
        TempFile.Write('21000600003506629111036000642  00000000005900001609240045300002024/PF/5889                                         16092415700 0');
        TempFile.Write('21000700003506629111037000643  00000000004100001609240045300002024/PF/5889                                         16092415700 0');
        TempFile.Write('21000800003506629111038000644  00000000047500001609240045300002024/PF/6201 +2K                                     16092415700 0');
        TempFile.Write('21000900003506629111039000645  00000000022900001609240045300002024/PF/6410                                         16092415700 0');
        TempFile.Write('21001000006667113656701000638  1000000011116800160924004030000ING : MASTERCARD  251     71136567-01/073 R.77113656716092415701 0');
        TempFile.Write('2200100000116                                                                                                                0 0');
        TempFile.Write('8157BE75363216340251                  EUR0000000022212960160924                                                                0');
        TempFile.Write('9               000056000000044788170000000040312650                                                                           1');
        TempFile.Write('0000016092430005        33610135  MY AMERICAN SHOP SRL      BBRUBEBB   00058315707 00000                                       2');
        TempFile.Write('12026BE75363216340251                  USD0000000022640040110924MY AMERICAN SHOP SRL      Compte à vue                       026');
        TempFile.Write('2100010000CAL/F/1322404000050  0000000037400000160924030520000Mouvement lié à la transaction FXForward             16092402601 0');
        TempFile.Write('2200010000       + 37.400,00FXN71322404  (ING Trade : DI1242640                                                              1 0');
        TempFile.Write('2300010000                                                                        0P00106)                                   0 1');
        TempFile.Write('3100010001CAL/F/1322404000050  030520000Transaction FX Forward avec la référence 71322404 Conclue avec ING Belgiu            0 1');
        TempFile.Write('3100010002CAL/F/1322404000050  030520000m SA/NV le 16/09/2024 ING vous a acheté 33.671,37 EUR ING vous a vendu 37            0 1');
        TempFile.Write('3100010003CAL/F/1322404000050  030520000.400,00 USD Taux de change: 1,110736                                                 0 1');
        TempFile.Write('3100010004CAL/F/1322404000050  030520000MAMERICBAS                                                                           0 0');
        TempFile.Write('21000200003771655794909000051  1000000059678000160924041010000Euroboisson 20248003                                 16092402601 0');
        TempFile.Write('2200020000                                                                                        NOSCCATT                   1 0');
        TempFile.Write('2300020000301710036013                      USDLaugin Solutions Inc                                                          0 1');
        TempFile.Write('31000200013771655794909000051  041010001001Laugin Solutions Inc                                                              1 0');
        TempFile.Write('3200020001 516 1ere Avenue Montreal CA                                                                                       0 1');
        TempFile.Write('31000200023771655794909000051  001500000Virement en euros (SEPA) De: PayPal Europe S.a.r.l. et Cie S.C.A 22-24 Bo            0 1');
        TempFile.Write('31000200033771655794909000051  04101000016H779456 Date valeur 16/09/2024 Lordre spécifie Tous frais à charge du              0 1');
        TempFile.Write('31000200043771655794909000051  041010000 bénéficiaire.Compte bénéf. 301710036013 Bénéficiaire : Laugin Solution              0 1');
        TempFile.Write('31000200053771655794909000051  041010000s Inc 516 1ere Avenue Montreal CA Communication Euroboisson 20248003 Corr            0 1');
        TempFile.Write('31000200063771655794909000051  041010000espondant : NOSCCATT BANK OF NOVA SCOTIA international banking division 4            0 1');
        TempFile.Write('31000200073771655794909000051  0410100004 KING STREET WEST Canada toronto ont m5h 1h1                                        0 1');
        TempFile.Write('31000200083771655794909000051  041010001004301710036013                                                                      0 1');
        TempFile.Write('31000200093771655794909000051  041010001001Laugin Solutions Inc                516 1ere Avenue Montreal CA                   0 1');
        TempFile.Write('31000200103771655794909000051  041010001002Euroboisson 20248003                                                              0 1');
        TempFile.Write('31000200113771655794909000051  041010001005NOSCCATT                                                                          0 1');
        TempFile.Write('31000200123771655794909000051  041010001105000000059678000000000059678000000100000000USD            CA00000005381            1 0');
        TempFile.Write('32000200127300                                                                                                               0 1');
        TempFile.Write('31000200133771655794909000051  041010000Pièce justificative en annexe                                                        0 0');
        TempFile.Write('8026BE75363216340251                  USD0000000000362040160924                                                                0');
        TempFile.Write('9               000027000000059678000000000037400000                                                                           2');
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine1(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 10000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '230058315713';
        CODAStatementLine."Statement Amount" := 498297;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := '*** 00/9906/86864***';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Bank Account No. Other Party" := '230058315713';
        CODAStatementLine."Name Other Party" := 'The Cannon Group PLC';
        CODAStatementLine."Address Other Party" := '192 Market Square';
        CODAStatementLine."City Other Party" := 'MECHELEN';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine2(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 20000;
        CODAStatementLine.ID := CODAStatementLine.ID::"Free Message";
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 0;
        CODAStatementLine.Transaction := 0;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'REF. 850719730107                             + 498.297 EUR';
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Attached to Line No." := 10000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine3(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 30000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4850743000074';
        CODAStatementLine."Statement Amount" := 6967;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 2;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'REF. **/36.9288';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine4(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 40000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '230058315713';
        CODAStatementLine."Statement Amount" := 100200;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := '*** 00/9906/84037***';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Bank Account No. Other Party" := '310054005646';
        CODAStatementLine."Name Other Party" := 'Deerfield Graphics Company';
        CODAStatementLine."Address Other Party" := '10 Deerfield Road';
        CODAStatementLine."City Other Party" := 'BRAS';
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/3', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine5(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 50000;
        CODAStatementLine.ID := CODAStatementLine.ID::"Free Message";
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 0;
        CODAStatementLine.Transaction := 0;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'REF. 850719730107                             + 100.200 EUR';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Attached to Line No." := 80000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/3', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine6(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 60000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4850750705981';
        CODAStatementLine."Statement Amount" := -1208;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 3;
        CODAStatementLine.Transaction := 3;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 107;
        CODAStatementLine."Statement Message" := '4001969689460002 00001602010000 ARAL MECHELEN    MECHELEN';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/4', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine7(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
        Customer: Record Customer;
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 70000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '788535710831';
        CODAStatementLine."Statement Amount" := 426053;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 50;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 101;
        CODAStatementLine."Statement Message" := '000010300285';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Bank Account No. Other Party" := '788535710831';
        Customer.Get('20000');
        CODAStatementLine."Name Other Party" := CopyStr(Customer.Name, 1, MaxStrLen(CODAStatementLine."Name Other Party"));
        CODAStatementLine."Address Other Party" := '153 Thomas Drive';
        CODAStatementLine."City Other Party" := 'BRUSSEL';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/5', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine8(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 80000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -182;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 3;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine9(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 90000;
        CODAStatementLine.ID := CODAStatementLine.ID::Information;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 3;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := 'RABOBANK NETHERLANDS';
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine10(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 100000;
        CODAStatementLine.ID := CODAStatementLine.ID::Information;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Transaction Type" := 3;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Statement Message" := 'TRANSFER ORDER CHARGES :                        EUR         5550,00';
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine11(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 110000;
        CODAStatementLine.ID := CODAStatementLine.ID::"Free Message";
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 0;
        CODAStatementLine.Transaction := 0;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Statement Message" := 'REF. 866447710582                                 FOLIO 01';
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine12(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 120000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Detail;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -32;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 8;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 11;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 106;
        CODAStatementLine."Statement Message" := '0000000000320000000150000002100000000 000000000032000';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6-1', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine13(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 130000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Detail;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -150;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 8;
        CODAStatementLine."Transaction Family" := 41;
        CODAStatementLine.Transaction := 37;
        CODAStatementLine."Transaction Category" := 13;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Attached to Line No." := 160000;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/6-2', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine14(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 140000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -220099;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 1;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Non standard format";
        CODAStatementLine."Type Standard Format Message" := 0;
        CODAStatementLine."Statement Message" := '101000010802665';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Bank Account No. Other Party" := '431068010811';
        CODAStatementLine."Name Other Party" := 'CoolWood Technologies';
        CODAStatementLine."Address Other Party" := '33 Hitech Drive';
        CODAStatementLine."City Other Party" := 'ANDERLECHT';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/7', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertSampleCODAStatementLine15(StatementNo: Code[20]; BankAccountNo: Code[20])
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine."Bank Account No." := BankAccountNo;
        CODAStatementLine."Statement No." := StatementNo;
        CODAStatementLine."Statement Line No." := 150000;
        CODAStatementLine.ID := CODAStatementLine.ID::Movement;
        CODAStatementLine.Type := CODAStatementLine.Type::Global;
        CODAStatementLine."Bank Reference No." := '4866447710582';
        CODAStatementLine."Statement Amount" := -1700;
        CODAStatementLine."Transaction Date" := CalcDate('<CM+30D>', WorkDate());
        CODAStatementLine."Transaction Type" := 0;
        CODAStatementLine."Transaction Family" := 1;
        CODAStatementLine.Transaction := 1;
        CODAStatementLine."Transaction Category" := 0;
        CODAStatementLine."Message Type" := CODAStatementLine."Message Type"::"Standard format";
        CODAStatementLine."Type Standard Format Message" := 101;
        CODAStatementLine."Statement Message" := '198411561414';
        CODAStatementLine."Posting Date" := CODAStatementLine."Transaction Date";
        CODAStatementLine."Globalisation Code" := 0;
        CODAStatementLine."Bank Account No. Other Party" := '431068011114';
        CODAStatementLine."Name Other Party" := 'MILLERS & CO';
        CODAStatementLine."Attached to Line No." := 0;
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::"G/L Account";
        CODAStatementLine."Document No." := CopyStr(StatementNo + '/8', 1, MaxStrLen(CODAStatementLine."Document No."));
        CODAStatementLine."Unapplied Amount" := CODAStatementLine."Statement Amount";
        CODAStatementLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine(StatementNo: Code[20]; StatementLineNo: Integer)
    var
        CODAStatementLine: Record "CODA Statement Line";
    begin
        CODAStatementLine.Init();
        CODAStatementLine.SetRange("Statement No.", StatementNo);
        CODAStatementLine.SetRange("Statement Line No.", StatementLineNo);

        CODAStatementLine.FindFirst();

        case StatementLineNo of
            10000, 30000, 40000:
                ValidateSampleCODAStatementLine1(CODAStatementLine);
            60000:
                ValidateSampleCODAStatementLine6(CODAStatementLine);
            70000:
                ValidateSampleCODAStatementLine7(CODAStatementLine);
            80000:
                ValidateSampleCODAStatementLine8(CODAStatementLine);
            120000:
                ValidateSampleCODAStatementLine12(CODAStatementLine);
            130000:
                ValidateSampleCODAStatementLine13(CODAStatementLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine1(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(CODAStatementLine."Statement Message", CODAStatementLine.Description, 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine6(CODAStatementLine: Record "CODA Statement Line")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get('499999');
        Assert.AreEqual(GLAccount.Name, CODAStatementLine.Description, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::"Partly applied", CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('499999', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Amount (LCY)", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-1208, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine7(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(CODAStatementLine."Name Other Party", CODAStatementLine.Description, 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Document No.", CODAStatementLine."Applies-to ID", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::Applied, CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Account Type"::Customer, CODAStatementLine."Account Type", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('20000', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Document Type"::Payment, CODAStatementLine."Document Type", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(426053, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Name Other Party", CODAStatementLine."Account Name", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine8(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-182, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine12(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::"Partly applied", CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('411000', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Amount (LCY)", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-32, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;

    [Scope('OnPrem')]
    procedure ValidateSampleCODAStatementLine13(CODAStatementLine: Record "CODA Statement Line")
    begin
        Assert.AreEqual(true, CODAStatementLine."System-Created Entry", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine.Description, CODAStatementLine."Application Information", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(CODAStatementLine."Application Status"::"Partly applied", CODAStatementLine."Application Status", 'Line ' +
          Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual('656000', CODAStatementLine."Account No.", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine.Amount, 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(0, CODAStatementLine."Amount (LCY)", 'Line ' + Format(CODAStatementLine."Statement Line No."));
        Assert.AreEqual(-150, CODAStatementLine."Unapplied Amount", 'Line ' + Format(CODAStatementLine."Statement Line No."));
    end;
}

