page 295 "Req. Wksh. Names"
{
    Caption = 'Req. Wksh. Names';
    DataCaptionExpression = DataCaption;
    PageType = List;
    SourceTable = "Requisition Wksh. Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the requisition worksheet you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a brief description of the requisition worksheet name you are creating.';
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
        area(processing)
        {
            action("Edit Worksheet")
            {
                ApplicationArea = Planning;
                Caption = 'Edit Worksheet';
                Image = OpenWorksheet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Make the worksheet lines editable.';

                trigger OnAction()
                begin
                    ReqJnlManagement.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        SetRange("Worksheet Template Name");
    end;

    trigger OnOpenPage()
    begin
        ReqJnlManagement.OpenJnlBatch(Rec);
    end;

    var
        ReqJnlManagement: Codeunit ReqJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        ReqWkshTmpl: Record "Req. Wksh. Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Worksheet Template Name") <> '' then
                if GetRangeMin("Worksheet Template Name") = GetRangeMax("Worksheet Template Name") then
                    if ReqWkshTmpl.Get(GetRangeMin("Worksheet Template Name")) then
                        exit(ReqWkshTmpl.Name + ' ' + ReqWkshTmpl.Description);
    end;
}

