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
}

