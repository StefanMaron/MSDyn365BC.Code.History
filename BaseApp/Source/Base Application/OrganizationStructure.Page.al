page 17384 "Organization Structure"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Organization Structure';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Position View Buffer";
    SourceTableTemporary = true;
    SourceTableView = SORTING(ID);
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentPositionNo; CurrentPositionNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reporting to';
                    TableRelation = Position;

                    trigger OnValidate()
                    begin
                        CurrentPositionNoOnAfterValida;
                    end;
                }
            }
            repeater(Control1)
            {
                IndentationColumn = Level;
                IndentationControls = "Position No.";
                ShowAsTree = true;
                ShowCaption = false;
                field("Position No."; "Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(EmployeeNames; EmployeeNames)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Name(s)';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = EmployeeNamesEmphasize;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Employee.Reset;
                        Employee.SetCurrentKey("Position No.");
                        Employee.SetRange("Position No.", "Position No.");
                        PAGE.Run(0, Employee);
                    end;
                }
                field("Manager No."; "Manager No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Position.""Organization Size"""; Position."Organization Size")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Org. Size';
                    Editable = false;
                }
                field("Position.""Job Title Code"""; Position."Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Job Title Code';
                    Editable = false;
                }
                field("Position.""Job Title Name"""; Position."Job Title Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Job Title Name';
                    Editable = false;
                }
                field("Position.""Org. Unit Code"""; Position."Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Org. Unit Code';
                    Editable = false;
                }
                field("Position.""Org. Unit Name"""; Position."Org. Unit Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Org. Unit Name';
                    Editable = false;
                }
                field(PositionAvailability; PositionAvailability)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vacant';
                    Editable = false;
                }
                field("Position.Rate"; Position.Rate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Max. Rate';
                    Editable = false;
                }
                field("Position.""Filled Rate"""; Position."Filled Rate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filled Rate';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Position")
            {
                Caption = '&Position';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Position Card";
                    RunPageLink = "No." = FIELD("Position No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Exp&and/Collapse")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exp&and/Collapse';
                    Image = ImportExport;
                    ToolTip = 'Expand or collapse the selected element.';

                    trigger OnAction()
                    begin
                        ToggleExpandCollapse;
                    end;
                }
                action("Expand All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xpand All';
                    Image = ExpandDepositLine;

                    trigger OnAction()
                    begin
                        ExpandAll;
                    end;
                }
                action("Collapse All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ollapse All';
                    Image = CollapseDepositLines;

                    trigger OnAction()
                    begin
                        CollapseAll;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Position.Get("Position No.");
        Position.CalcFields("Organization Size", "Filled Rate");
        if Position.Rate - Position."Filled Rate" = 0 then
            PositionAvailability := 1
        else
            PositionAvailability := 0;

        EmployeeNames := '';
        Employee.Reset;
        Employee.SetCurrentKey("Position No.");
        Employee.SetRange("Position No.", "Position No.");
        if Employee.FindSet then
            repeat
                if EmployeeNames = '' then
                    EmployeeNames := Employee.GetFullName
                else
                    EmployeeNames := CopyStr(EmployeeNames + ';' + Employee.GetFullName, 1, MaxStrLen(EmployeeNames));
            until Employee.Next = 0;

        if EmployeeNames = '' then
            EmployeeNames := Text14700;

        EmployeeNamesOnFormat;
    end;

    trigger OnOpenPage()
    var
        Position2: Record Position;
    begin
        if CurrentPositionNo = '' then begin
            Position2.Reset;
            Position2.SetCurrentKey("Parent Position No.");
            Position2.SetRange("Parent Position No.", '');
            Position2.FindFirst;
            CurrentPositionNo := Position2."No.";
        end;

        InitTempTable;
        ExpandAll;
    end;

    var
        Employee: Record Employee;
        Position: Record Position;
        ViewBuffer: Record "Position View Buffer" temporary;
        CurrentPositionNo: Code[20];
        CurrentLevel: Integer;
        PositionAvailability: Integer;
        EmployeeNames: Text[250];
        Text14700: Label 'Open Position';
        [InDataSet]
        EmployeeNamesEmphasize: Boolean;

    local procedure InitTempTable()
    var
        Position2: Record Position;
    begin
        ViewBuffer.DeleteAll;
        ViewBuffer.Reset;

        Position2.Get(CurrentPositionNo);
        CurrentLevel := Position2.Level;
        ViewBuffer.ID := 1;
        ViewBuffer."Position No." := CurrentPositionNo;
        ViewBuffer."Manager No." := Position2."Parent Position No.";
        ViewBuffer.Hide := false;
        ViewBuffer.Expanded := false;
        ViewBuffer.Level := Position2.Level - CurrentLevel;
        ViewBuffer.Insert;

        EnlistChildren(CurrentPositionNo);
        UpdateView(1);
    end;

    [Scope('OnPrem')]
    procedure EnlistChildren(ReportingTo: Code[20])
    var
        Position2: Record Position;
    begin
        Position2.Reset;
        Position2.SetCurrentKey("Parent Position No.");
        Position2.SetRange("Parent Position No.", ReportingTo);
        if Position2.FindSet then
            repeat
                ViewBuffer.ID := ViewBuffer.ID + 1;
                ViewBuffer."Position No." := Position2."No.";
                ViewBuffer."Manager No." := Position2."Parent Position No.";
                ViewBuffer.Hide := true;
                ViewBuffer.Expanded := false;
                ViewBuffer.Level := Position2.Level - CurrentLevel;
                ViewBuffer.Insert;
                Position2.CalcFields("Organization Size");
                if Position2."Organization Size" > 0 then
                    EnlistChildren(Position2."No.")
            until Position2.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateView(ID: Integer)
    begin
        DeleteAll;
        if ViewBuffer.FindFirst then
            repeat
                if not ViewBuffer.Hide then begin
                    Rec := ViewBuffer;
                    Insert;
                end;
            until ViewBuffer.Next = 0;
        Get(ID);
    end;

    local procedure ExpandAll()
    var
        Position: Record Position;
    begin
        ViewBuffer.ModifyAll(Hide, false);
        if ViewBuffer.FindFirst then
            repeat
                if not ViewBuffer.Expanded then begin
                    Position.Get("Position No.");
                    Position.CalcFields("Organization Size");
                    if Position."Organization Size" > 0 then begin
                        ViewBuffer.Expanded := true;
                        ViewBuffer.Modify;
                    end;
                end;
            until ViewBuffer.Next = 0;

        UpdateView(1);
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure CollapseAll()
    begin
        InitTempTable;
    end;

    [Scope('OnPrem')]
    procedure CollapseChildren(PositionNo: Code[20])
    var
        CurrViewBufferElement: Record "Position View Buffer" temporary;
    begin
        ViewBuffer.SetRange("Manager No.", PositionNo);
        if ViewBuffer.FindSet then
            repeat
                if not ViewBuffer.Hide then begin
                    ViewBuffer.Hide := true;
                    if ViewBuffer.Expanded then
                        ViewBuffer.Expanded := false;
                    ViewBuffer.Modify;
                    CurrViewBufferElement := ViewBuffer;
                    CollapseChildren(ViewBuffer."Position No.");
                    ViewBuffer := CurrViewBufferElement;
                end;
            until ViewBuffer.Next = 0;
    end;

    local procedure ToggleExpandCollapse()
    begin
        if Expanded then begin // Collapse one level
            ViewBuffer.Get(ID);
            ViewBuffer.Expanded := false;
            ViewBuffer.Modify;
            CollapseChildren(ViewBuffer."Position No.");
        end else begin // Expand one level
            ViewBuffer.Reset;
            ViewBuffer.SetCurrentKey("Manager No.");
            ViewBuffer.SetRange("Manager No.", "Position No.");
            if ViewBuffer.FindSet then begin
                repeat
                    if ViewBuffer.Hide then begin
                        ViewBuffer.Hide := false;
                        ViewBuffer.Modify;
                    end;
                until ViewBuffer.Next = 0;
                ViewBuffer.Get(ID);
                ViewBuffer.Expanded := true;
                ViewBuffer.Modify;
            end;
        end;
        ViewBuffer.SetRange("Manager No.");
        UpdateView(ID);
    end;

    local procedure CurrentPositionNoOnAfterValida()
    begin
        InitTempTable;
        ExpandAll;
        CurrPage.Update(false);
    end;

    local procedure EmployeeNamesOnFormat()
    begin
        if Position."Organization Size" > 0 then
            EmployeeNamesEmphasize := true;
        if EmployeeNames = Text14700 then;
    end;
}

