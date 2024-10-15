codeunit 10630 "Export EHF Reminder"
{

    trigger OnRun()
    begin
    end;

    procedure ExportEFHReminder30(DocumentVariant: Variant; DocumentView: Text)
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        TempRecordExportBuffer: Record "Record Export Buffer" temporary;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DocumentVariant);
        RecRef.SetView(DocumentView);
        if not RecRef.FindSet() then
            exit;

        repeat
            TempRecordExportBuffer.Init();
            TempRecordExportBuffer.ID += 1;
            TempRecordExportBuffer.RecordID := RecRef.RecordId();
            TempRecordExportBuffer.Insert();
        until RecRef.Next() = 0;

        with TempRecordExportBuffer do begin
            FindSet();
            repeat
                RecRef.Get(RecordID);
                case RecRef.Number() of
                    DATABASE::"Issued Reminder Header":
                        begin
                            RecRef.SetTable(IssuedReminderHeader);
                            ServerFilePath := GenerateXMLFile(IssuedReminderHeader);
                            ClientFileName := GetClientFileName(IssuedReminderHeader.TableCaption(), IssuedReminderHeader."No.");
                            ZipFileName := GetZipFileName(IssuedReminderHeader.TableCaption(), IssuedReminderHeader."No.");
                            Modify();
                        end;
                    DATABASE::"Issued Fin. Charge Memo Header":
                        begin
                            RecRef.SetTable(IssuedFinChargeMemoHeader);
                            ServerFilePath := GenerateXMLFile(IssuedFinChargeMemoHeader);
                            ClientFileName := GetClientFileName(IssuedFinChargeMemoHeader.TableCaption(), IssuedFinChargeMemoHeader."No.");
                            ZipFileName := GetZipFileName(IssuedFinChargeMemoHeader.TableCaption(), IssuedFinChargeMemoHeader."No.");
                            Modify();
                        end;
                end;
            until Next() = 0;
        end;

        SendElectronically(TempRecordExportBuffer);
    end;

    procedure GenerateXMLFile(VariantRec: Variant): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        EHFReminder30: XMLport "EHF Reminder 3.0";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        EHFReminder30.Initialize(VariantRec);
        EHFReminder30.SetDestination(OutStream);
        EHFReminder30.Export();
        OutFile.Close();

        exit(CopyStr(XmlServerPath, 1, 250));
    end;

    local procedure GetClientFileName(TableCaption: Text; DocumentNo: Code[20]): Text[250]
    begin
        exit(
          CopyStr(StrSubstNo('%1 - %2.xml', TableCaption, DocumentNo), 1, 250));
    end;

    local procedure GetZipFileName(TableCaption: Text; DocumentNo: Code[20]): Text[250]
    begin
        exit(
          CopyStr(StrSubstNo('%1 - %2.zip', TableCaption, DocumentNo), 1, 250));
    end;

    local procedure SendElectronically(var RecordExportBuffer: Record "Record Export Buffer")
    var
        EntryTempBlob: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        EntryFileInStream: InStream;
        ZipFileOutStream: OutStream;
        ClientFile: Text;
    begin
        if not RecordExportBuffer.FindSet() then
            exit;

        if RecordExportBuffer.Count() > 1 then begin
            TempBlob.CreateOutStream(ZipFileOutStream);
            DataCompression.CreateZipArchive();
            ClientFile := RecordExportBuffer.ZipFileName;
            repeat
                RecordExportBuffer.GetFileContent(EntryTempBlob);
                EntryTempBlob.CreateInStream(EntryFileInStream);
                DataCompression.AddEntry(EntryFileInStream, RecordExportBuffer.ClientFileName);
            until RecordExportBuffer.Next() = 0;
            DataCompression.SaveZipArchive(ZipFileOutStream);
            DataCompression.CloseZipArchive();
        end else begin
            RecordExportBuffer.GetFileContent(TempBlob);
            ClientFile := RecordExportBuffer.ClientFileName;
        end;

        ReportDistributionManagement.SaveFileOnClient(TempBlob, ClientFile);
    end;
}

