table 14917 "CD No. Format"
{
    Caption = 'CD No. Format';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; Format; Code[30])
        {
            Caption = 'Format';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'Invalid format: %1.';
        Text005: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZÇüéâäà­åçêëèïîìÄÅÉæÆôöòûùÿÖÜø£Ø×ƒ';
        InvtSetup: Record "Inventory Setup";
        InvtSetupRead: Boolean;

    [Scope('OnPrem')]
    procedure Check(CDNo: Code[30]; ShowError: Boolean): Boolean
    var
        CDNoFormat: Record "CD No. Format";
        Success: Boolean;
    begin
        GetInvtSetup;
        if not InvtSetup."Check CD No. Format" then
            exit;

        Success := false;
        CDNoFormat.Reset;
        if CDNoFormat.FindSet then
            repeat
                Success := Compare(CDNo, CDNoFormat.Format);
            until (CDNoFormat.Next = 0) or Success;

        if ShowError and (not Success) then
            Error(Text001, CDNo);

        exit(Success);
    end;

    [Scope('OnPrem')]
    procedure Compare(CDNo: Code[30]; Format: Text[30]): Boolean
    var
        i: Integer;
        Cf: Text[1];
        Ce: Text[1];
        Check: Boolean;
    begin
        Check := true;
        if StrLen(CDNo) = StrLen(Format) then
            for i := 1 to StrLen(CDNo) do begin
                Cf := CopyStr(Format, i, 1);
                Ce := CopyStr(CDNo, i, 1);
                case Cf of
                    '#':
                        if not ((Ce >= '0') and (Ce <= '9')) then
                            Check := false;
                    '@':
                        if StrPos(Text005, UpperCase(Ce)) = 0 then
                            Check := false;
                    else
                        if not ((Cf = Ce) or (Cf = '?')) then
                            Check := false
                end;
            end
        else
            Check := false;
        exit(Check);
    end;

    [Scope('OnPrem')]
    procedure GetInvtSetup()
    begin
        if not InvtSetupRead then begin
            InvtSetup.Get;
            InvtSetupRead := true;
        end;
    end;
}

