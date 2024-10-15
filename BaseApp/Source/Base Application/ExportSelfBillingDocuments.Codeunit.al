codeunit 12185 "Export Self-Billing Documents"
{

    trigger OnRun()
    begin
    end;

    var
        SelfBillingDocumentNotExportedErr: Label 'The self-billing document has not been created.';
        MultipleEntriesQst: Label 'There are multiple VAT entries for the selected document. Do you want to export all?';

    procedure Run(var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        ServerFilePath: Text[250];
        ClientFileName: Text[250];
    begin
        ExportSelfBillingDocuments(ServerFilePath, ClientFileName, SelectedVATEntry, AllVATEntry);
        ReportDistributionManagement.SaveFileOnClient(ServerFilePath, ClientFileName);
    end;

    procedure RunWithFileNameSave(var ServerFilePath: Text[250]; var ClientFileName: Text[250]; var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    begin
        ExportSelfBillingDocuments(ServerFilePath, ClientFileName, SelectedVATEntry, AllVATEntry);
    end;

    local procedure ExportSelfBillingDocuments(var ServerFilePath: Text[250]; var ClientFileName: Text[250]; var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    var
        TempVATEntry: Record "VAT Entry" temporary;
        RecordExportBuffer: Record "Record Export Buffer";
        TempErrorMessage: Record "Error Message" temporary;
        DataCompression: Codeunit "Data Compression";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ZipFile: File;
        ServerTempFileInStream: InStream;
        ZipFileOutStream: OutStream;
        IsMissingServerFile: Boolean;
        StartID: Integer;
        EndID: Integer;
    begin
        with SelectedVATEntry do begin
            SetCurrentKey("Document No.", "Posting Date", "Unrealized VAT Entry No.");
            if FindSet then
                repeat
                    CopyVATEntriesByDocNoAndPostingDateToBuffer(TempVATEntry, SelectedVATEntry, AllVATEntry);
                    DoExport(TempVATEntry, TempErrorMessage, RecordExportBuffer);
                    if RecordExportBuffer.ServerFilePath = '' then
                        IsMissingServerFile := true;
                    if StartID = 0 then
                        StartID := RecordExportBuffer.ID;
                    EndID := RecordExportBuffer.ID;
                until Next = 0;

            TempErrorMessage.ShowErrorMessages(true);
            if IsMissingServerFile then
                Error(SelfBillingDocumentNotExportedErr);

            RecordExportBuffer.SetRange(ID, StartID, EndID);
            if RecordExportBuffer.Count > 1 then begin
                ServerFilePath := CopyStr(FileManagement.ServerTempFileName('zip'), 1, 250);
                ClientFileName := CopyStr(RecordExportBuffer.ZipFileName, 1, 250);
                ZipFile.Create(ServerFilePath);
                ZipFile.CreateOutStream(ZipFileOutStream);
                DataCompression.CreateZipArchive;
                RecordExportBuffer.FindSet;
                repeat
                    FileManagement.BLOBImportFromServerFile(TempBlob, RecordExportBuffer.ServerFilePath);
                    TempBlob.CreateInStream(ServerTempFileInStream);
                    DataCompression.AddEntry(ServerTempFileInStream, RecordExportBuffer.ClientFileName);
                until RecordExportBuffer.Next = 0;
                DataCompression.SaveZipArchive(ZipFileOutStream);
                DataCompression.CloseZipArchive;
                ZipFile.Close;
            end else
                if RecordExportBuffer.FindFirst then begin
                    ServerFilePath := RecordExportBuffer.ServerFilePath;
                    ClientFileName := RecordExportBuffer.ClientFileName;
                end;

            RecordExportBuffer.DeleteAll();
        end;
    end;

    local procedure CopyVATEntriesByDocNoAndPostingDateToBuffer(var TempVATEntry: Record "VAT Entry" temporary; var SelectedVATEntry: Record "VAT Entry"; var AllVATEntry: Record "VAT Entry")
    var
        HeaderEntryNo: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.DeleteAll();
        with SelectedVATEntry do begin
            SetRange("Document No.", "Document No.");
            SetRange("Posting Date", "Posting Date");
            repeat
                TempVATEntry := SelectedVATEntry;
                TempVATEntry.Insert();
                if TempVATEntry."Related Entry No." = 0 then
                    HeaderEntryNo := TempVATEntry."Entry No.";
            until Next = 0;

            CopyFilter("Document No.", AllVATEntry."Document No.");
            CopyFilter("Posting Date", AllVATEntry."Posting Date");
            AllVATEntry.SetRange("Related Entry No.", HeaderEntryNo);
            if not AllVATEntry.IsEmpty then
                if Confirm(MultipleEntriesQst, false) then begin
                    AllVATEntry.FindSet;
                    repeat
                        TempVATEntry := AllVATEntry;
                        if TempVATEntry.Insert() then;
                    until AllVATEntry.Next = 0;
                end;
            AllVATEntry.SetRange("Related Entry No.");

            SetRange("Document No.");
            SetRange("Posting Date");
        end;
    end;

    local procedure DoExport(var TempVATEntry: Record "VAT Entry" temporary; var TempErrorMessage: Record "Error Message" temporary; var RecordExportBuffer: Record "Record Export Buffer")
    var
        ErrorMessage: Record "Error Message";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        ExportFatturaPADocument: Codeunit "Export FatturaPA Document";
    begin
        ErrorMessage.SetContext(TempVATEntry);
        ErrorMessage.ClearLog;

        FatturaDocHelper.InitializeErrorLog(TempVATEntry);
        FatturaDocHelper.CollectSelfBillingDocInformation(TempFatturaHeader, TempFatturaLine, TempVATEntry);

        Clear(RecordExportBuffer);
        RecordExportBuffer.RecordID := TempVATEntry.RecordId;
        if not FatturaDocHelper.HasErrors then begin
            RecordExportBuffer.ClientFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.xml';
            RecordExportBuffer.ZipFileName := FatturaDocHelper.GetFileName(TempFatturaHeader."Progressive No.") + '.zip';
            RecordExportBuffer.ServerFilePath :=
              ExportFatturaPADocument.GenerateXMLFile(TempFatturaLine, TempFatturaHeader, RecordExportBuffer.ClientFileName);
        end;
        RecordExportBuffer.Insert(true);

        TempErrorMessage.CopyFromContext(TempVATEntry);
        ErrorMessage.ClearLog;
    end;
}

