page 2865 "Native - Sales Tax Setup"
{
    Caption = 'Native - Sales Tax Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Native - API Tax Setup";
    SourceTableTemporary = true;

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
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName';
                    Editable = false;
                }
                field(default; Default)
                {
                    ApplicationArea = All;
                    Caption = 'default';
                }
                field(city; City)
                {
                    ApplicationArea = All;
                    Caption = 'city';
                }
                field(cityRate; "City Rate")
                {
                    ApplicationArea = All;
                    Caption = 'cityRate';
                }
                field(state; State)
                {
                    ApplicationArea = All;
                    Caption = 'state';
                }
                field(stateRate; "State Rate")
                {
                    ApplicationArea = All;
                    Caption = 'stateRate';
                }
                field(canadaGstHstDescription; "GST or HST Description")
                {
                    ApplicationArea = All;
                    Caption = 'canadaGstHstDescription';
                }
                field(canadaGstHstRate; "GST or HST Rate")
                {
                    ApplicationArea = All;
                    Caption = 'canadaGstHstRate';
                }
                field(canadaPstDescription; "PST Description")
                {
                    ApplicationArea = All;
                    Caption = 'canadaPstDescription';
                }
                field(canadaPstRate; "PST Rate")
                {
                    ApplicationArea = All;
                    Caption = 'canadaPstRate';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SaveChanges(xRec);
        ReloadRecord;

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        SaveChanges(xRec);
        ReloadRecord;

        exit(false);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
        LoadSetupRecords;

        if Type = Type::VAT then
            DeleteAll();
    end;

    var
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
}

