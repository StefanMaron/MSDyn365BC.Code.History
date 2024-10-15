page 14951 "KLADR Addresses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'KLADR Addresses';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "KLADR Address";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category.';
                }
                field(Index; Index)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(GNINMB; GNINMB)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            field("GetFullAddress(Code)"; GetFullAddress(Code))
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(btnHierarchy)
            {
                Caption = '&Functions';
                Image = "Action";
                action("Expand Level")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expand Level';
                    Image = ExpandDepositLine;
                    ShortCutKey = 'F7';

                    trigger OnAction()
                    begin
                        NextLevel(Code);
                    end;
                }
                action("Collapse Level")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Collapse Level';
                    Image = CollapseDepositLines;

                    trigger OnAction()
                    begin
                        PrevLevel(Code);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if HierarchyMode then
            UpdateForm;
    end;

    var
        CurrAddrCode: Text[19];
        HierarchyMode: Boolean;

    [Scope('OnPrem')]
    procedure SetAddrCode(AddrCode: Code[19]; Mode: Boolean)
    begin
        CurrAddrCode := AddrCode;
        HierarchyMode := Mode;
    end;

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        SetCurrentKey(Parent);
        if CurrAddrCode = '' then
            SetRange(Parent, '')
        else
            SetRange(Parent, GetParentCode(CurrAddrCode, Level));
        FilterGroup(3);
    end;

    [Scope('OnPrem')]
    procedure NextLevel(AddrCode: Code[19])
    var
        KLADRAddr: Record "KLADR Address";
    begin
        if Level = 6 then
            exit;
        KLADRAddr.SetCurrentKey(Parent);
        KLADRAddr.SetRange(Parent, AddrCode);
        if KLADRAddr.FindFirst then begin
            Reset;
            SetCurrentKey(Parent);
            SetRange(Parent, AddrCode);
            FilterGroup(3);
        end;
    end;

    [Scope('OnPrem')]
    procedure PrevLevel(AddrCode: Code[19])
    var
        TempParent: Text[19];
    begin
        if Level = 1 then
            exit;
        TempParent := Parent;
        Reset;
        Code := GetParentCode(AddrCode, Level);
        Find;
        SetCurrentKey(Parent);
        SetRange(Parent, GetParentCode(TempParent, GetLevel(TempParent)));
        FilterGroup(3);
    end;
}

