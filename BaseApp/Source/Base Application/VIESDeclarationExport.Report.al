#if not CLEAN17
report 31066 "VIES Declaration Export"
{
    Caption = 'VIES Declaration Export (Obsolete)';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("VIES Declaration Header"; "VIES Declaration Header")
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            var
                VIESLine: Record "VIES Declaration Line";
            begin
                TestField(Status, Status::Released);
                TempVIESLine.DeleteAll();
                TempVIESLine.Reset();
                VIESLine.SetRange("VIES Declaration No.", "No.");
                if VIESLine.FindSet then
                    repeat
                        TempVIESLine := VIESLine;
                        TempVIESLine.Insert();
                    until VIESLine.Next() = 0;
                ExportToXML;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TempVIESLine: Record "VIES Declaration Line" temporary;
        FileName: Text;
        Text26500: Label 'Export of VIES';
        Text26501: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        ToFileNameTxt: Label 'Default.xml';

    local procedure ExportToXML()
    var
        FileMgt: Codeunit "File Management";
        VIESDeclarationXML: XMLport "VIES Declaration";
        OutputFile: File;
        OutputStream: OutStream;
        ClientFileName: Text[250];
    begin
        OutputFile.TextMode(true);
        OutputFile.WriteMode(true);

        ClientFileName := ToFileNameTxt;
        FileName := FileMgt.ServerTempFileName('.xml');
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutputStream);

        VIESDeclarationXML.SetHeader("VIES Declaration Header");
        VIESDeclarationXML.SetLines(TempVIESLine);
        VIESDeclarationXML.SetDestination(OutputStream);
        VIESDeclarationXML.Export;
        OutputFile.Close;

        Download(FileName, Text26500, '', Text26501, ClientFileName);
        Erase(FileName);
    end;
}


#endif