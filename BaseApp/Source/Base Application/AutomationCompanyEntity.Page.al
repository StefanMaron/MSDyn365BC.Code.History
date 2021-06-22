page 5440 "Automation Company Entity"
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    Caption = 'automationCompany', Locked = true;
    DelayedInsert = true;
    EntityName = 'automationCompany';
    EntitySetName = 'automationCompanies';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = Company;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'name', Locked = true;
                    Editable = false;
                }
                field(evaluationCompany; "Evaluation Company")
                {
                    ApplicationArea = All;
                    Caption = 'evaluationCompany', Locked = true;
                    Editable = false;
                }
                field(displayName; "Display Name")
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    NotBlank = true;
                }
                field(businessProfileId; "Business Profile Id")
                {
                    ApplicationArea = All;
                    Caption = 'businessProfileId', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Name := CopyStr("Display Name", 1, MaxStrLen(Name));
        "Evaluation Company" := false;
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(AutomationAPIManagement);
    end;

    var
        AutomationAPIManagement: Codeunit "Automation - API Management";
}

