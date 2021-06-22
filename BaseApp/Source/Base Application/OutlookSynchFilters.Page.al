page 5303 "Outlook Synch. Filters"
{
    AutoSplitKey = true;
    Caption = 'Outlook Synch. Filters';
    DataCaptionFields = "Filter Type";
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Outlook Synch. Filter";

    layout
    {
        area(content)
        {
            group("Filter")
            {
                Caption = 'Filter';
                field(RecomposeFilterExpression; RecomposeFilterExpression)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filtering Expression';
                    Editable = false;
                    ToolTip = 'Specifies a filter defined on the lines of the Outlook Synch. Filters window. The expression in this field is composed according to Dynamics 365 filter syntax.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Field No."; "Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the field with values that are used in the filter expression. A value in this field is appropriate if you specified the number of the table in the Table No. field.';
                }
                field(GetFieldCaption; GetFieldCaption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    ToolTip = 'Specifies the name of the field whose values will be used in the filter expression. The program fills in this field when you specify the number of the field in the Field No. field.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of filtration is applied. There are three options you can choose from:';

                    trigger OnValidate()
                    begin
                        CheckValueAvailability;
                    end;
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = ValueEditable;
                    ToolTip = 'Specifies the value that is compared with the value in the Field No. field.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CheckValueAvailability;
    end;

    trigger OnInit()
    begin
        ValueEditable := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ExistentFilterExpression: Text[250];
    begin
        ExistentFilterExpression := OSynchSetupMgt.ComposeFilterExpression("Record GUID", "Filter Type");
        if (StrLen(ExistentFilterExpression) +
            StrLen(GetFieldCaption) +
            StrLen(Format(Type)) +
            StrLen(Value)) > MaxStrLen(ExistentFilterExpression)
        then
            Error(Text001);
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetTablesNo(TableLeftNo, TableRightNo);
        CheckValueAvailability;
    end;

    var
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        TableLeftNo: Integer;
        TableRightNo: Integer;
        Text001: Label 'The filter cannot be processed because the expression is too long. Redefine your criteria.';
        [InDataSet]
        ValueEditable: Boolean;

    procedure SetTables(LeftNo: Integer; RightNo: Integer)
    begin
        TableLeftNo := LeftNo;
        TableRightNo := RightNo;
    end;

    procedure CheckValueAvailability()
    begin
        if Type = Type::FIELD then
            ValueEditable := false
        else
            ValueEditable := true;
    end;
}

