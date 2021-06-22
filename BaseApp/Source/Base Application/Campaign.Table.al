table 5071 Campaign
{
    Caption = 'Campaign';
    DataCaptionFields = "No.", Description;
    LookupPageID = "Campaign List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    RMSetup.Get();
                    NoSeriesMgt.TestManual(RMSetup."Campaign Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" > 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
            end;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if ("Ending Date" < "Starting Date") and ("Ending Date" > 0D) then
                    Error(Text001, FieldCaption("Ending Date"), FieldCaption("Starting Date"));
            end;
        }
        field(5; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(6; Comment; Boolean)
        {
            CalcFormula = Exist ("Rlshp. Mgt. Comment Line" WHERE("Table Name" = CONST(Campaign),
                                                                  "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(8; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(9; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(10; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(11; "Status Code"; Code[10])
        {
            Caption = 'Status Code';
            TableRelation = "Campaign Status";
        }
        field(12; "Target Contacts Contacted"; Integer)
        {
            CalcFormula = Count ("Interaction Log Entry" WHERE("Campaign No." = FIELD("No."),
                                                               "Campaign Target" = CONST(true),
                                                               Canceled = CONST(false),
                                                               Date = FIELD("Date Filter"),
                                                               Postponed = CONST(false)));
            Caption = 'Target Contacts Contacted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Contacts Responded"; Integer)
        {
            CalcFormula = Count ("Interaction Log Entry" WHERE("Campaign No." = FIELD("No."),
                                                               "Campaign Response" = CONST(true),
                                                               Canceled = CONST(false),
                                                               Date = FIELD("Date Filter"),
                                                               Postponed = CONST(false)));
            Caption = 'Contacts Responded';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Duration (Min.)"; Decimal)
        {
            CalcFormula = Sum ("Interaction Log Entry"."Duration (Min.)" WHERE("Campaign No." = FIELD("No."),
                                                                               Canceled = CONST(false),
                                                                               Date = FIELD("Date Filter"),
                                                                               Postponed = CONST(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Interaction Log Entry"."Cost (LCY)" WHERE("Campaign No." = FIELD("No."),
                                                                          Canceled = CONST(false),
                                                                          Date = FIELD("Date Filter"),
                                                                          Postponed = CONST(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "No. of Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE("Campaign No." = FIELD("No."),
                                                           Active = CONST(true)));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Estimated Value (LCY)" WHERE("Campaign No." = FIELD("No."),
                                                                                 Active = CONST(true)));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE("Campaign No." = FIELD("No."),
                                                                                      Active = CONST(true)));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(23; "Action Taken Filter"; Option)
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Next,Previous,Updated,Jumped,Won,Lost';
            OptionMembers = " ",Next,Previous,Updated,Jumped,Won,Lost;
        }
        field(24; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(25; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage WHERE("Sales Cycle Code" = FIELD("Sales Cycle Filter"));
        }
        field(26; "Probability % Filter"; Decimal)
        {
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(27; "Completed % Filter"; Decimal)
        {
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(28; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(29; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(30; "Estimated Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(31; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(32; "Chances of Success % Filter"; Decimal)
        {
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(33; "Task Status Filter"; Option)
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Not Started,In Progress,Completed,Waiting,Postponed';
            OptionMembers = "Not Started","In Progress",Completed,Waiting,Postponed;
        }
        field(34; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(35; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(36; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(37; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(38; "Opportunity Entry Exists"; Boolean)
        {
            CalcFormula = Exist ("Opportunity Entry" WHERE("Campaign No." = FIELD("No."),
                                                           Active = CONST(true),
                                                           "Salesperson Code" = FIELD("Salesperson Filter"),
                                                           "Contact No." = FIELD("Contact Filter"),
                                                           "Contact Company No." = FIELD("Contact Company Filter"),
                                                           "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                           "Action Taken" = FIELD("Action Taken Filter"),
                                                           "Estimated Value (LCY)" = FIELD("Estimated Value Filter"),
                                                           "Calcd. Current Value (LCY)" = FIELD("Calcd. Current Value Filter"),
                                                           "Completed %" = FIELD("Completed % Filter"),
                                                           "Chances of Success %" = FIELD("Chances of Success % Filter"),
                                                           "Probability %" = FIELD("Probability % Filter"),
                                                           "Estimated Close Date" = FIELD("Date Filter"),
                                                           "Close Opportunity Code" = FIELD("Close Opportunity Filter")));
            Caption = 'Opportunity Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; "Task Entry Exists"; Boolean)
        {
            CalcFormula = Exist ("To-do" WHERE("Campaign No." = FIELD("No."),
                                               "Contact No." = FIELD("Contact Filter"),
                                               "Contact Company No." = FIELD("Contact Company Filter"),
                                               "Salesperson Code" = FIELD("Salesperson Filter"),
                                               "Team Code" = FIELD("Team Filter"),
                                               Status = FIELD("Task Status Filter"),
                                               Closed = FIELD("Task Closed Filter"),
                                               Priority = FIELD("Priority Filter"),
                                               Date = FIELD("Date Filter")));
            Caption = 'Task Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(41; Activated; Boolean)
        {
            CalcFormula = Exist ("Campaign Target Group" WHERE("Campaign No." = FIELD("No.")));
            Caption = 'Activated';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Salesperson Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Starting Date", "Ending Date", "Status Code")
        {
        }
    }

    trigger OnDelete()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
    begin
        DimMgt.DeleteDefaultDim(DATABASE::Campaign, "No.");

        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::Campaign);
        RMCommentLine.SetRange("No.", "No.");
        RMCommentLine.DeleteAll();

        CampaignEntry.SetCurrentKey("Campaign No.");
        CampaignEntry.SetRange("Campaign No.", "No.");
        CampaignEntry.DeleteAll();

        CampaignMgmt.DeactivateCampaign(Rec, false);

        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
        SalesPrice.SetRange("Sales Code", "No.");
        SalesPrice.DeleteAll();

        SalesLineDisc.SetRange("Sales Type", SalesLineDisc."Sales Type"::Campaign);
        SalesLineDisc.SetRange("Sales Code", "No.");
        SalesLineDisc.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            RMSetup.Get();
            RMSetup.TestField("Campaign Nos.");
            NoSeriesMgt.InitSeries(RMSetup."Campaign Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        if "Salesperson Code" = '' then
            SetDefaultSalesperson;

        DimMgt.UpdateDefaultDim(
          DATABASE::Campaign, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        if ("Starting Date" <> xRec."Starting Date") or
           ("Ending Date" <> xRec."Ending Date")
        then
            UpdateDates;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::Campaign, xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        Text000: Label '%1 must be before %2.';
        Text001: Label '%1 must be after %2.';
        RMSetup: Record "Marketing Setup";
        Campaign: Record Campaign;
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        CampaignEntry: Record "Campaign Entry";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        CampaignMgmt: Codeunit "Campaign Target Group Mgt";

    procedure AssistEdit(OldCampaign: Record Campaign): Boolean
    begin
        with Campaign do begin
            Campaign := Rec;
            RMSetup.Get();
            RMSetup.TestField("Campaign Nos.");
            if NoSeriesMgt.SelectSeries(RMSetup."Campaign Nos.", OldCampaign."No. Series", "No. Series") then begin
                RMSetup.Get();
                RMSetup.TestField("Campaign Nos.");
                NoSeriesMgt.SetSeries("No.");
                Rec := Campaign;
                exit(true);
            end;
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Campaign, "No.", FieldNumber, ShortcutDimCode);
            Modify;
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure UpdateDates()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
        SalesPrice2: Record "Sales Price";
        SalesLineDisc2: Record "Sales Line Discount";
    begin
        Modify;
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
        SalesPrice.SetRange("Sales Code", "No.");
        SalesPrice.LockTable();
        if SalesPrice.Find('-') then
            repeat
                SalesPrice2 := SalesPrice;
                SalesPrice.Delete();
                SalesPrice2.Validate("Starting Date", "Starting Date");
                SalesPrice2.Insert(true);
                SalesPrice2.Validate("Ending Date", "Ending Date");
                SalesPrice2.Modify();
            until SalesPrice.Next = 0;

        SalesLineDisc.SetRange("Sales Type", SalesLineDisc."Sales Type"::Campaign);
        SalesLineDisc.SetRange("Sales Code", "No.");
        SalesLineDisc.LockTable();
        if SalesLineDisc.Find('-') then
            repeat
                SalesLineDisc2 := SalesLineDisc;
                SalesLineDisc.Delete();
                SalesLineDisc2.Validate("Starting Date", "Starting Date");
                SalesLineDisc2.Insert(true);
                SalesLineDisc2.Validate("Ending Date", "Ending Date");
                SalesLineDisc2.Modify();
            until SalesLineDisc.Next = 0;
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(Campaign: Record Campaign; xCampaign: Record Campaign; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(Campaign: Record Campaign; xCampaign: Record Campaign; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

