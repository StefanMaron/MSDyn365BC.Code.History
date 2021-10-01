#if not CLEAN19
page 9896 "SmartList Import Results"
{
    Caption = 'SmartList Import Results';
    Editable = false;
    Extensible = false;
    PageType = List;
    SourceTable = "SmartList Import Results";
    SourceTableView = sorting(Success, Name) order(ascending);
    UsageCategory = None;
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    Tooltip = 'Specifies the query name.';
                }
                field(Result; ResultTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Result';
                    StyleExpr = ResultStyle;
                    Tooltip = 'Specifies whether or not the import was successful.';
                }
                field(Errors; Errors)
                {
                    ApplicationArea = All;
                    Caption = 'Errors';
                    Tooltip = 'Specifies the error details.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Success then begin
            ResultStyle := 'favorable';
            ResultTxt := 'Success';
        end else begin
            ResultStyle := 'unfavorable';
            ResultTxt := 'Failure';
        end;
    end;

    var
        ResultStyle: Text;
        ResultTxt: Text;
}
#endif