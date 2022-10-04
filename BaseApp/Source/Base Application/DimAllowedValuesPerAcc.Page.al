page 546 "Dim. Allowed Values per Acc."
{
    Caption = 'Allowed Dimension Values';
    PageType = Worksheet;
    DataCaptionExpression = GetCaption();
    SourceTable = "Dim. Value per Account";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = DimensionValueName;
                ShowCaption = false;
                field(DimensionValueCode; "Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the code for the dimension value.';
                }
                field(DimensionValueName; "Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies a descriptive name for the dimension value.';
                }
                field(Allowed; Allowed)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies whether the related record can be posted in transactions.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetAllowed)
            {
                ApplicationArea = Dimensions;
                Caption = 'Set Allowed';
                Image = Approve;
                ToolTip = 'Set selected dimension values allowed.';

                trigger OnAction()
                var
                    DimValuePerAccount: Record "Dim. Value per Account";
                begin
                    CurrPage.SetSelectionFilter(DimValuePerAccount);
                    if DimValuePerAccount.FindSet() then
                        repeat
                            Get(DimValuePerAccount."Table ID", DimValuePerAccount."No.", DimValuePerAccount."Dimension Code", DimValuePerAccount."Dimension Value Code");
                            Validate(Allowed, true);
                            Modify();
                        until DimValuePerAccount.Next() = 0;
                end;
            }
            action(SetDisallowed)
            {
                ApplicationArea = Dimensions;
                Caption = 'Set Disallowed';
                Image = Reject;
                ToolTip = 'Specify the dimension values that cannot be used for an account.';

                trigger OnAction()
                var
                    DimValuePerAccount: Record "Dim. Value per Account";
                begin
                    CurrPage.SetSelectionFilter(DimValuePerAccount);
                    if DimValuePerAccount.FindSet() then
                        repeat
                            Get(DimValuePerAccount."Table ID", DimValuePerAccount."No.", DimValuePerAccount."Dimension Code", DimValuePerAccount."Dimension Value Code");
                            Validate(Allowed, false);
                            Modify();
                        until DimValuePerAccount.Next() = 0;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SetAllowed_Promoted; SetAllowed)
                {
                }
                actionref(SetDisallowed_Promoted; SetDisallowed)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then begin
            Reset();
            DimMgt.CheckIfNoAllowedValuesSelected(Rec);
        end;
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        [InDataSet]
        Emphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;

    local procedure FormatLine()
    begin
        CalcFields("Dimension Value Type", Indentation);
        Emphasize := "Dimension Value Type" <> "Dimension Value Type"::Standard;
        NameIndent := Indentation;
    end;

    procedure SetBufferData(var TempDimValuePerAccount: Record "Dim. Value per Account" temporary)
    begin
        if TempDimValuePerAccount.FindSet() then
            repeat
                Rec := TempDimValuePerAccount;
                Insert();
            until TempDimValuePerAccount.Next() = 0;
    end;

    procedure GetBufferData(var TempDimValuePerAccount: Record "Dim. Value per Account" temporary)
    begin
        Reset();
        if FindSet() then
            repeat
                TempDimValuePerAccount.Get("Table ID", "No.", "Dimension Code", "Dimension Value Code");
                TempDimValuePerAccount.Allowed := Allowed;
                TempDimValuePerAccount.Modify();
            until Next() = 0;
    end;
}