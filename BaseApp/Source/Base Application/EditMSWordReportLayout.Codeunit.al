codeunit 9650 "Edit MS Word Report Layout"
{
    TableNo = "Custom Report Layout";

    trigger OnRun()
    begin
        EditReportLayout(Rec);
    end;

    var
        LoadDocQst: Label 'The report layout document has been edited in Word.\\Do you want to import the changes?';
        WordNotFoundErr: Label 'You cannot edit the report layout because Microsoft Word is not available on your computer. To edit the report layout, you must install a supported version of Word.';
        WaitMsg: Label 'Please wait while the report layout opens in Word.\After the report layout opens in Word, make changes to the layout,\and then close the Word document to continue.';
        Window: Dialog;

    local procedure EditReportLayout(var CustomReportLayout: Record "Custom Report Layout")
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: Codeunit WordApplicationHandler;
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
        [RunOnClient]
        WordDocument: DotNet Document;
        [RunOnClient]
        WdWindowState: DotNet WdWindowState;
        [RunOnClient]
        WordHelper: DotNet WordHelper;
        [RunOnClient]
        WordHandler: DotNet WordHandler;
        FileName: Text;
        NewFileName: Text;
        LoadModifiedDoc: Boolean;
    begin
        CustomReportLayout.TestLayout;

        WordManagement.Activate(WordApplicationHandler, 9650);
        if not WordManagement.TryGetWord(WordApplication) then begin
            WordManagement.Deactivate(9650);
            Error(WordNotFoundErr);
        end;

        Window.Open(WaitMsg);

        CustomReportLayout.GetLayoutBlob(TempBlob);
        FileName := FileMgt.BLOBExport(TempBlob, FileName, false);

        // Open word and wait for the document to be closed
        WordHandler := WordHandler.WordHandler;
        WordDocument := WordHelper.CallOpen(WordApplication, FileName, false, false);
        WordDocument.ActiveWindow.Caption := CustomReportLayout."Report Name" + ' ' + CustomReportLayout.Description;
        WordDocument.Application.Visible := true; // Visible before WindowState KB176866 - http://support.microsoft.com/kb/176866
        WordDocument.ActiveWindow.WindowState := WdWindowState.wdWindowStateNormal;

        // Push the word app to foreground
        WordApplication.WindowState := WdWindowState.wdWindowStateMinimize;
        WordApplication.Visible := true;
        WordApplication.Activate;
        WordApplication.WindowState := WdWindowState.wdWindowStateNormal;

        WordDocument.Saved := true;
        WordDocument.Application.Activate;

        NewFileName := WordHandler.WaitForDocument(WordDocument);
        Window.Close;
        WordManagement.Deactivate(9650);

        LoadModifiedDoc := Confirm(LoadDocQst);

        if LoadModifiedDoc then begin
            FileMgt.BLOBImport(TempBlob, NewFileName);
            CustomReportLayout.ImportLayoutBlob(TempBlob, '');
        end;

        FileMgt.DeleteClientFile(FileName);
        if FileName <> NewFileName then
            FileMgt.DeleteClientFile(NewFileName);
    end;
}

