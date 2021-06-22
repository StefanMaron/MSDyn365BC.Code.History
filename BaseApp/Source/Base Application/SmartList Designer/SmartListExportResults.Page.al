page 9893 "SmartList Export Results"
{
    Caption = 'SmartList Export Results';
    Editable = false;
    Extensible = false;
    PageType = List;
    SourceTable = "SmartList Export Results";
    SourceTableView = sorting(Success, Name) order(ascending);
    UsageCategory = None;

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
                    Tooltip = 'Specifies whether or not the export was successful.';
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