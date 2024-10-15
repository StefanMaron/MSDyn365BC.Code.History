table 14950 "KLADR Address"
{
    Caption = 'KLADR Address';

    fields
    {
        field(1; "Code"; Code[19])
        {
            Caption = 'Code';
        }
        field(2; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(3; Parent; Code[19])
        {
            Caption = 'Parent';
            Editable = false;
        }
        field(4; Name; Text[40])
        {
            Caption = 'Name';
        }
        field(5; "Category Code"; Text[10])
        {
            Caption = 'Category Code';
        }
        field(6; Index; Code[6])
        {
            Caption = 'Index';
        }
        field(7; GNINMB; Code[4])
        {
            Caption = 'GNINMB';
        }
        field(8; "Category Name"; Text[30])
        {
            CalcFormula = Lookup ("KLADR Category".Name WHERE(Code = FIELD("Category Code"),
                                                              Level = FIELD(Level)));
            Caption = 'Category Name';
            FieldClass = FlowField;
        }
        field(9; Building; Code[10])
        {
            Caption = 'Building';
        }
        field(10; Status; Code[1])
        {
            Caption = 'Status';
        }
        field(11; UNO; Code[4])
        {
            Caption = 'UNO';
        }
        field(12; OKATO; Code[11])
        {
            Caption = 'OKATO';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Parent)
        {
        }
        key(Key3; Level, Parent, Name)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        UpdateHierarchy;
    end;

    trigger OnModify()
    begin
        UpdateHierarchy;
    end;

    trigger OnRename()
    begin
        UpdateHierarchy;
    end;

    var
        Result: Integer;

    [Scope('OnPrem')]
    procedure GetLevel(AddrCode: Code[19]): Integer
    var
        i: Integer;
        SplittedCode: array[7] of Code[4];
    begin
        SplitCode(AddrCode, SplittedCode);
        i := 6;
        while i > 0 do begin
            if Evaluate(Result, SplittedCode[i]) then
                if Result <> 0 then
                    exit(i);
            i := i - 1;
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure UpdateHierarchy()
    begin
        Level := GetLevel(Code);
        Parent := GetParentCode(Code, Level);
    end;

    [Scope('OnPrem')]
    procedure SplitCode(AddrCode: Code[19]; var SplittedCode: array[7] of Code[4])
    begin
        Clear(SplittedCode);
        if StrLen(AddrCode) > 17 then
            SplittedCode[6] := CopyStr(AddrCode, 16, 4);
        if StrLen(AddrCode) > 13 then begin
            SplittedCode[5] := CopyStr(AddrCode, 12, 4);
            SplittedCode[7] := CopyStr(AddrCode, 16, 2);
        end;
        if StrLen(AddrCode) = 13 then
            SplittedCode[7] := CopyStr(AddrCode, 12, 2);
        SplittedCode[1] := CopyStr(AddrCode, 1, 2);
        SplittedCode[2] := CopyStr(AddrCode, 3, 3);
        SplittedCode[3] := CopyStr(AddrCode, 6, 3);
        SplittedCode[4] := CopyStr(AddrCode, 9, 3);
    end;

    [Scope('OnPrem')]
    procedure GetParentCode(AddrCode: Code[19]; Level: Integer) Parent: Code[19]
    begin
        case Level of
            0, 1:
                Parent := '';
            2:
                Parent := PadStr(PadStr(AddrCode, 2), 13, '0');
            3:
                Parent := PadStr(PadStr(AddrCode, 5), 13, '0');
            4:
                Parent := PadStr(PadStr(AddrCode, 8), 13, '0');
            5:
                Parent := PadStr(PadStr(AddrCode, 11), 13, '0');
            6:
                Parent := PadStr(PadStr(AddrCode, 15), 17, '0');
            7:
                Parent := AddrCode;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFullAddress(AddrCode: Code[19]): Text[250]
    var
        KLADRAddr: Record "KLADR Address";
        FullAddress: Text[250];
        CurrCode: Code[19];
    begin
        CurrCode := AddrCode;
        while KLADRAddr.Get(CurrCode) do begin
            FullAddress := ', ' + KLADRAddr."Category Code" + ' ' + KLADRAddr.Name + ' ' + FullAddress;
            CurrCode := KLADRAddr.Parent;
        end;
        exit(CopyStr(FullAddress, 3));
    end;
}

