page 7323 "Whse. Journal Batches"
{
    Caption = 'Whse. Journal Batches';
    DataCaptionExpression = DataCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Warehouse Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name of the warehouse journal batch.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the warehouse journal batch.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the journal batch applies.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Registering No. Series"; "Registering No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign document numbers to the warehouse entries that are registered from this journal batch.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = false;
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupNewBatch;
    end;

    local procedure DataCaption(): Text[250]
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Journal Template Name") <> '' then
                if GetRangeMin("Journal Template Name") = GetRangeMax("Journal Template Name") then
                    if WhseJnlTemplate.Get(GetRangeMin("Journal Template Name")) then
                        exit(WhseJnlTemplate.Name + ' ' + WhseJnlTemplate.Description);
    end;
}

