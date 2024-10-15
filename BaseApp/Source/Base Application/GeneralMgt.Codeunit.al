codeunit 11501 GeneralMgt
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'The folder name must end with a slash character, i.e. %1.';

    [Scope('OnPrem')]
    procedure CheckFolderName(_Input: Text[250])
    begin
        // Check for ending slash of folder name
        if _Input = '' then
            exit;

        if not (CopyStr(_Input, StrLen(_Input)) in ['\', '/']) then
            Message(Text001, 'c:\data\');
    end;

    [Scope('OnPrem')]
    procedure CheckCurrency(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not (CurrencyCode = '') then begin
            exit(CurrencyCode);
        end else begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("LCY Code");
            exit(GeneralLedgerSetup."LCY Code");
        end;
    end;

    [Scope('OnPrem')]
    procedure RemoveCrLf(FileName: Text[1024]; TempFileName: Text[1024]; A2A: Boolean): Text[1024]
    var
        SourceFile: File;
        TargetFile: File;
        Z: Char;
        ZT: Text[2];
        FileMgt: Codeunit "File Management";
    begin
        // Removes CR/LF in File. Rename Original file and write again w/o CR/LF.
        SourceFile.TextMode := false;
        SourceFile.WriteMode := false;
        SourceFile.Open(TempFileName);

        TargetFile.TextMode := false;
        TargetFile.WriteMode := true;
        TargetFile.Create(FileMgt.ServerTempFileName(''));

        while SourceFile.Read(Z) = 1 do begin
            if not (Z in [10, 13]) then
                TargetFile.Write(Z);
        end;

        SourceFile.Close;
        TempFileName := TargetFile.Name;
        TargetFile.Close;
        if FileMgt.IsLocalFileSystemAccessible then
            FileMgt.DownloadToFile(TempFileName, FileName);

        exit(TempFileName);
    end;
}

