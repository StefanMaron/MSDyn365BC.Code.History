table 13 "Salesperson/Purchaser"
{
    Caption = 'Salesperson/Purchaser';
    DataCaptionFields = "Code", Name;
    LookupPageID = "Salespersons/Purchasers";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField(Code);
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Commission %"; Decimal)
        {
            Caption = 'Commission %';
            DecimalPlaces = 2 : 2;
            MaxValue = 100;
            MinValue = 0;
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ExtendedDatatype = Person;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';
        }
        field(5050; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(5051; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(5052; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if ("Search E-Mail" = UpperCase(xRec."E-Mail")) or ("Search E-Mail" = '') then
                    "Search E-Mail" := "E-Mail";
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(5053; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(5054; "Next Task Date"; Date)
        {
            CalcFormula = Min ("To-do".Date WHERE("Salesperson Code" = FIELD(Code),
                                                  Closed = CONST(false),
                                                  "System To-do Type" = FILTER(Organizer | "Salesperson Attendee")));
            Caption = 'Next Task Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5055; "No. of Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE("Salesperson Code" = FIELD(Code),
                                                           Active = CONST(true),
                                                           "Estimated Close Date" = FIELD("Date Filter"),
                                                           "Action Taken" = FIELD("Action Taken Filter"),
                                                           "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                           "Probability %" = FIELD("Probability % Filter"),
                                                           "Completed %" = FIELD("Completed % Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5056; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Estimated Value (LCY)" WHERE("Salesperson Code" = FIELD(Code),
                                                                                 Active = CONST(true),
                                                                                 "Estimated Close Date" = FIELD("Date Filter"),
                                                                                 "Action Taken" = FIELD("Action Taken Filter"),
                                                                                 "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                 "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                 "Probability %" = FIELD("Probability % Filter"),
                                                                                 "Completed %" = FIELD("Completed % Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5057; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE("Salesperson Code" = FIELD(Code),
                                                                                      Active = CONST(true),
                                                                                      "Estimated Close Date" = FIELD("Date Filter"),
                                                                                      "Action Taken" = FIELD("Action Taken Filter"),
                                                                                      "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                      "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                      "Probability %" = FIELD("Probability % Filter"),
                                                                                      "Completed %" = FIELD("Completed % Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5058; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5059; "No. of Interactions"; Integer)
        {
            CalcFormula = Count ("Interaction Log Entry" WHERE("Salesperson Code" = FIELD(Code),
                                                               Canceled = CONST(false),
                                                               Date = FIELD("Date Filter"),
                                                               Postponed = CONST(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5060; "Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Interaction Log Entry"."Cost (LCY)" WHERE("Salesperson Code" = FIELD(Code),
                                                                          Canceled = CONST(false),
                                                                          Date = FIELD("Date Filter"),
                                                                          Postponed = CONST(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5061; "Duration (Min.)"; Decimal)
        {
            CalcFormula = Sum ("Interaction Log Entry"."Duration (Min.)" WHERE("Salesperson Code" = FIELD(Code),
                                                                               Canceled = CONST(false),
                                                                               Date = FIELD("Date Filter"),
                                                                               Postponed = CONST(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5062; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(5063; "Action Taken Filter"; Option)
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Next,Previous,Updated,Jumped,Won,Lost';
            OptionMembers = " ",Next,Previous,Updated,Jumped,Won,Lost;
        }
        field(5064; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(5065; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage WHERE("Sales Cycle Code" = FIELD("Sales Cycle Filter"));
        }
        field(5066; "Probability % Filter"; Decimal)
        {
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5067; "Completed % Filter"; Decimal)
        {
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5068; "Avg. Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Average ("Opportunity Entry"."Estimated Value (LCY)" WHERE("Salesperson Code" = FIELD(Code),
                                                                                     Active = CONST(true),
                                                                                     "Estimated Close Date" = FIELD("Date Filter"),
                                                                                     "Action Taken" = FIELD("Action Taken Filter"),
                                                                                     "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                     "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                     "Probability %" = FIELD("Probability % Filter"),
                                                                                     "Completed %" = FIELD("Completed % Filter")));
            Caption = 'Avg. Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5069; "Avg.Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Average ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE("Salesperson Code" = FIELD(Code),
                                                                                          Active = CONST(true),
                                                                                          "Estimated Close Date" = FIELD("Date Filter"),
                                                                                          "Action Taken" = FIELD("Action Taken Filter"),
                                                                                          "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                                                          "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                                                          "Probability %" = FIELD("Probability % Filter"),
                                                                                          "Completed %" = FIELD("Completed % Filter")));
            Caption = 'Avg.Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5070; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(5071; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(5072; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(5073; "Estimated Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(5074; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(5075; "Chances of Success % Filter"; Decimal)
        {
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5076; "Task Status Filter"; Option)
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Not Started,In Progress,Completed,Waiting,Postponed';
            OptionMembers = "Not Started","In Progress",Completed,Waiting,Postponed;
        }
        field(5077; "Closed Task Filter"; Boolean)
        {
            Caption = 'Closed Task Filter';
            FieldClass = FlowFilter;
        }
        field(5078; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(5079; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(5082; "Opportunity Entry Exists"; Boolean)
        {
            CalcFormula = Exist ("Opportunity Entry" WHERE("Salesperson Code" = FIELD(Code),
                                                           Active = CONST(true),
                                                           "Contact No." = FIELD("Contact Filter"),
                                                           "Contact Company No." = FIELD("Contact Company Filter"),
                                                           "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                           "Campaign No." = FIELD("Campaign Filter"),
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
        field(5083; "Task Entry Exists"; Boolean)
        {
            CalcFormula = Exist ("To-do" WHERE("Salesperson Code" = FIELD(Code),
                                               "Contact No." = FIELD("Contact Filter"),
                                               "Contact Company No." = FIELD("Contact Company Filter"),
                                               "Campaign No." = FIELD("Campaign Filter"),
                                               "Team Code" = FIELD("Team Filter"),
                                               Status = FIELD("Task Status Filter"),
                                               Closed = FIELD("Closed Task Filter"),
                                               Priority = FIELD("Priority Filter"),
                                               Date = FIELD("Date Filter")));
            Caption = 'Task Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5084; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(5085; "Search E-Mail"; Code[80])
        {
            Caption = 'Search Email';
        }
        field(5086; "E-Mail 2"; Text[80])
        {
            Caption = 'Email 2';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail 2");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Search E-Mail")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Name, Image)
        {
        }
    }

    trigger OnDelete()
    var
        TeamSalesperson: Record "Team Salesperson";
        TodoTask: Record "To-do";
        Opportunity: Record Opportunity;
    begin
        TodoTask.Reset();
        TodoTask.SetCurrentKey("Salesperson Code", Closed);
        TodoTask.SetRange("Salesperson Code", Code);
        TodoTask.SetRange(Closed, false);
        if not TodoTask.IsEmpty() then
            Error(CannotDeleteBecauseActiveTasksErr, Code);

        Opportunity.SetRange("Salesperson Code", Code);
        Opportunity.SetRange(Closed, false);
        if not Opportunity.IsEmpty() then
            Error(CannotDeleteBecauseActiveOpportunitiesErr, Code);

        TeamSalesperson.Reset();
        TeamSalesperson.SetRange("Salesperson Code", Code);
        TeamSalesperson.DeleteAll();
        DimMgt.DeleteDefaultDim(DATABASE::"Salesperson/Purchaser", Code);
    end;

    trigger OnInsert()
    begin
        Validate(Code);
        DimMgt.UpdateDefaultDim(
          DATABASE::"Salesperson/Purchaser", Code,
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        Validate(Code);
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Salesperson/Purchaser", xRec.Code, Code);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        PostActionTxt: Label 'post';
        CreateActionTxt: Label 'create';
        SalespersonTxt: Label 'Salesperson';
        PurchaserTxt: Label 'Purchaser';
        CannotDeleteBecauseActiveTasksErr: Label 'You cannot delete the salesperson/purchaser with code %1 because it has open tasks.', Comment = '%1 = Salesperson/Purchaser code.';
        BlockedSalesPersonPurchErr: Label 'You cannot %1 this document because %2 %3 is blocked due to privacy.', Comment = '%1 = post or create, %2 = Salesperson / Purchaser, %3 = salesperson / purchaser code.';
        PrivacyBlockedGenericTxt: Label 'Privacy Blocked must not be true for %1 %2.', Comment = '%1 = Salesperson / Purchaser, %2 = salesperson / purchaser code.';
        CannotDeleteBecauseActiveOpportunitiesErr: Label 'You cannot delete the salesperson/purchaser with code %1 because it has open opportunities.', Comment = '%1 = Salesperson/Purchaser code.';

    procedure CreateInteraction()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        TempSegmentLine.CreateInteractionFromSalesperson(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Salesperson/Purchaser", Code, FieldNumber, ShortcutDimCode);
            Modify;
        end;
	
        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure GetPrivacyBlockedTransactionText(SalespersonPurchaser2: Record "Salesperson/Purchaser"; IsPostAction: Boolean; IsSalesperson: Boolean): Text[150]
    var
        "Action": Text[30];
        Type: Text[20];
    begin
        if IsPostAction then
            Action := PostActionTxt
        else
            Action := CreateActionTxt;
        if IsSalesperson then
            Type := SalespersonTxt
        else
            Type := PurchaserTxt;
        exit(StrSubstNo(BlockedSalesPersonPurchErr, Action, Type, SalespersonPurchaser2.Code));
    end;

    procedure GetPrivacyBlockedGenericText(SalespersonPurchaser2: Record "Salesperson/Purchaser"; IsSalesperson: Boolean): Text[150]
    var
        Type: Text[20];
    begin
        if IsSalesperson then
            Type := SalespersonTxt
        else
            Type := PurchaserTxt;
        exit(StrSubstNo(PrivacyBlockedGenericTxt, Type, SalespersonPurchaser2.Code));
    end;

    procedure VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser2: Record "Salesperson/Purchaser"): Boolean
    begin
        if SalespersonPurchaser2."Privacy Blocked" then
            exit(true);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var xSalespersonPurchaser: Record "Salesperson/Purchaser"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var xSalespersonPurchaser: Record "Salesperson/Purchaser"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

