table 5050 Contact
{
    Caption = 'Contact';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Contact List";
    LookupPageID = "Contact List";
    Permissions = TableData "Sales Header" = rm,
                  TableData "Contact Alt. Address" = rd,
                  TableData "Contact Alt. Addr. Date Range" = rd,
                  TableData "Contact Business Relation" = rd,
                  TableData "Contact Mailing Group" = rd,
                  TableData "Contact Industry Group" = rd,
                  TableData "Contact Web Source" = rd,
                  TableData "Rlshp. Mgt. Comment Line" = rd,
                  TableData "Interaction Log Entry" = rm,
                  TableData "Contact Job Responsibility" = rd,
                  TableData "To-do" = rm,
                  TableData "Contact Profile Answer" = rd,
                  TableData Opportunity = rm,
                  TableData "Opportunity Entry" = rm;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    RMSetup.Get();
                    NoSeriesMgt.TestManual(RMSetup."Contact Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                NameBreakdown;
                ProcessNameChange;
            end;
        }
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupCity(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateCity(Rec, PostCode);

                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);

                OnAfterValidateCity(Rec, xRec);
            end;
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(29; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                ValidateSalesPerson;
            end;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");

                if "Country/Region Code" <> xRec."Country/Region Code" then
                    VATRegistrationValidation;
            end;
        }
        field(38; Comment; Boolean)
        {
            CalcFormula = Exist ("Rlshp. Mgt. Comment Line" WHERE("Table Name" = CONST(Contact),
                                                                  "No." = FIELD("No."),
                                                                  "Sub No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(86; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            begin
                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." <> xRec."VAT Registration No." then
                    VATRegistrationValidation;
            end;
        }
        field(89; Picture; BLOB)
        {
            Caption = 'Picture';
            ObsoleteReason = 'Replaced by Image field';
            ObsoleteState = Pending;
            SubType = Bitmap;
            ObsoleteTag = '15.0';
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupPostCode(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidatePostCode(Rec, PostCode);

                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);

                OnAfterValidatePostCode(Rec, xRec);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "E-Mail" = '' then begin
                    SetSearchEmail();
                    exit;
                end;
                MailManagement.CheckValidEmailAddresses("E-Mail");
                SetSearchEmail();
            end;
        }
        field(103; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ExtendedDatatype = Person;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';

            trigger OnValidate()
            begin
                if not "Privacy Blocked" then
                    if Minor then
                        if not "Parental Consent Received" then
                            Error(ParentalConsentReceivedErr, "No.");
            end;
        }
        field(151; Minor; Boolean)
        {
            Caption = 'Minor';

            trigger OnValidate()
            begin
                if Minor then
                    Validate("Privacy Blocked", true);
            end;
        }
        field(152; "Parental Consent Received"; Boolean)
        {
            Caption = 'Parental Consent Received';

            trigger OnValidate()
            begin
                Validate("Privacy Blocked", true);
            end;
        }
        field(5050; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Company,Person';
            OptionMembers = Company,Person;

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("No." <> '') then begin
                    TypeChange;
                    Modify;
                end;
            end;
        }
        field(5051; "Company No."; Code[20])
        {
            Caption = 'Company No.';
            TableRelation = Contact WHERE(Type = CONST(Company));

            trigger OnValidate()
            var
                SegLine: Record "Segment Line";
                Cont: Record Contact;
            begin
                if Cont.Get("Company No.") then
                    InheritCompanyToPersonData(Cont)
                else
                    Clear("Company Name");

                if "Company No." = xRec."Company No." then
                    exit;

                TestField(Type, Type::Person);

                SegLine.SetRange("Contact No.", "No.");
                if not SegLine.IsEmpty then
                    Error(Text012, FieldCaption("Company No."));

                UpdateCompanyNo();
            end;
        }
        field(5052; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
            TableRelation = Contact.Name WHERE(Type = CONST(Company));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Company No.", GetCompNo("Company Name"));
            end;
        }
        field(5053; "Lookup Contact No."; Code[20])
        {
            Caption = 'Lookup Contact No.';
            Editable = false;
            TableRelation = Contact;

            trigger OnValidate()
            begin
                if Type = Type::Company then
                    "Lookup Contact No." := ''
                else
                    "Lookup Contact No." := "No.";
            end;
        }
        field(5054; "First Name"; Text[30])
        {
            Caption = 'First Name';

            trigger OnValidate()
            begin
                Name := CalculatedName;
                ProcessNameChange;
            end;
        }
        field(5055; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';

            trigger OnValidate()
            begin
                Name := CalculatedName;
                ProcessNameChange;
            end;
        }
        field(5056; Surname; Text[30])
        {
            Caption = 'Surname';

            trigger OnValidate()
            begin
                Name := CalculatedName;
                ProcessNameChange;
            end;
        }
        field(5058; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(5059; Initials; Text[30])
        {
            Caption = 'Initials';
        }
        field(5060; "Extension No."; Text[30])
        {
            Caption = 'Extension No.';
        }
        field(5061; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(5062; Pager; Text[30])
        {
            Caption = 'Pager';
        }
        field(5063; "Organizational Level Code"; Code[10])
        {
            Caption = 'Organizational Level Code';
            TableRelation = "Organizational Level";
        }
        field(5064; "Exclude from Segment"; Boolean)
        {
            Caption = 'Exclude from Segment';
        }
        field(5065; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5066; "Next Task Date"; Date)
        {
            CalcFormula = Min ("To-do".Date WHERE("Contact Company No." = FIELD("Company No."),
                                                  "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                  Closed = CONST(false),
                                                  "System To-do Type" = CONST("Contact Attendee")));
            Caption = 'Next Task Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5067; "Last Date Attempted"; Date)
        {
            CalcFormula = Max ("Interaction Log Entry".Date WHERE("Contact Company No." = FIELD("Company No."),
                                                                  "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                                  "Initiated By" = CONST(Us),
                                                                  Postponed = CONST(false)));
            Caption = 'Last Date Attempted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5068; "Date of Last Interaction"; Date)
        {
            CalcFormula = Max ("Interaction Log Entry".Date WHERE("Contact Company No." = FIELD("Company No."),
                                                                  "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                                  "Attempt Failed" = CONST(false),
                                                                  Postponed = CONST(false)));
            Caption = 'Date of Last Interaction';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5069; "No. of Job Responsibilities"; Integer)
        {
            CalcFormula = Count ("Contact Job Responsibility" WHERE("Contact No." = FIELD("No.")));
            Caption = 'No. of Job Responsibilities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5070; "No. of Industry Groups"; Integer)
        {
            CalcFormula = Count ("Contact Industry Group" WHERE("Contact No." = FIELD("Company No.")));
            Caption = 'No. of Industry Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5071; "No. of Business Relations"; Integer)
        {
            CalcFormula = Count ("Contact Business Relation" WHERE("Contact No." = FIELD("Company No.")));
            Caption = 'No. of Business Relations';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5072; "No. of Mailing Groups"; Integer)
        {
            CalcFormula = Count ("Contact Mailing Group" WHERE("Contact No." = FIELD("No.")));
            Caption = 'No. of Mailing Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5073; "External ID"; Code[20])
        {
            Caption = 'External ID';
        }
        field(5074; "No. of Interactions"; Integer)
        {
            CalcFormula = Count ("Interaction Log Entry" WHERE("Contact Company No." = FIELD(FILTER("Company No.")),
                                                               Canceled = CONST(false),
                                                               "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                               Date = FIELD("Date Filter"),
                                                               Postponed = CONST(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5076; "Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Interaction Log Entry"."Cost (LCY)" WHERE("Contact Company No." = FIELD("Company No."),
                                                                          Canceled = CONST(false),
                                                                          "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                                          Date = FIELD("Date Filter"),
                                                                          Postponed = CONST(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5077; "Duration (Min.)"; Decimal)
        {
            CalcFormula = Sum ("Interaction Log Entry"."Duration (Min.)" WHERE("Contact Company No." = FIELD("Company No."),
                                                                               Canceled = CONST(false),
                                                                               "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                                               Date = FIELD("Date Filter"),
                                                                               Postponed = CONST(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5078; "No. of Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE(Active = CONST(true),
                                                           "Contact Company No." = FIELD("Company No."),
                                                           "Estimated Close Date" = FIELD("Date Filter"),
                                                           "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                           "Action Taken" = FIELD("Action Taken Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5079; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Estimated Value (LCY)" WHERE(Active = CONST(true),
                                                                                 "Contact Company No." = FIELD("Company No."),
                                                                                 "Estimated Close Date" = FIELD("Date Filter"),
                                                                                 "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                                                 "Action Taken" = FIELD("Action Taken Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5080; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE(Active = CONST(true),
                                                                                      "Contact Company No." = FIELD("Company No."),
                                                                                      "Estimated Close Date" = FIELD("Date Filter"),
                                                                                      "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                                                      "Action Taken" = FIELD("Action Taken Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5082; "Opportunity Entry Exists"; Boolean)
        {
            CalcFormula = Exist ("Opportunity Entry" WHERE(Active = CONST(true),
                                                           "Contact Company No." = FIELD("Company No."),
                                                           "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                                           "Sales Cycle Code" = FIELD("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = FIELD("Sales Cycle Stage Filter"),
                                                           "Salesperson Code" = FIELD("Salesperson Filter"),
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
            CalcFormula = Exist ("To-do" WHERE("Contact Company No." = FIELD("Company No."),
                                               "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                               "Team Code" = FIELD("Team Filter"),
                                               "Salesperson Code" = FIELD("Salesperson Filter"),
                                               "Campaign No." = FIELD("Campaign Filter"),
                                               Date = FIELD("Date Filter"),
                                               Status = FIELD("Task Status Filter"),
                                               Priority = FIELD("Priority Filter"),
                                               Closed = FIELD("Task Closed Filter")));
            Caption = 'Task Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5084; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(5085; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(5087; "Action Taken Filter"; Option)
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Next,Previous,Updated,Jumped,Won,Lost';
            OptionMembers = " ",Next,Previous,Updated,Jumped,Won,Lost;
        }
        field(5088; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(5089; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage WHERE("Sales Cycle Code" = FIELD("Sales Cycle Filter"));
        }
        field(5090; "Probability % Filter"; Decimal)
        {
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5091; "Completed % Filter"; Decimal)
        {
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5092; "Estimated Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(5093; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(5094; "Chances of Success % Filter"; Decimal)
        {
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5095; "Task Status Filter"; Option)
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Not Started,In Progress,Completed,Waiting,Postponed';
            OptionMembers = "Not Started","In Progress",Completed,Waiting,Postponed;
        }
        field(5096; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(5097; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(5098; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(5099; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(5100; "Correspondence Type"; Option)
        {
            Caption = 'Correspondence Type';
            OptionCaption = ' ,Hard Copy,Email,Fax';
            OptionMembers = " ","Hard Copy",Email,Fax;
        }
        field(5101; "Salutation Code"; Code[10])
        {
            Caption = 'Salutation Code';
            TableRelation = Salutation;
        }
        field(5102; "Search E-Mail"; Code[80])
        {
            Caption = 'Search Email';
        }
        field(5104; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
        }
        field(5105; "E-Mail 2"; Text[80])
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
        field(5106; "Job Responsibility Filter"; Code[10])
        {
            Caption = 'Job Responsibility Filter';
            FieldClass = FlowFilter;
            TableRelation = "Job Responsibility";
        }
        field(8050; "Xrm Id"; Guid)
        {
            Caption = 'Xrm Id';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Company Name", "Company No.", Type, Name)
        {
        }
        key(Key4; "Company No.")
        {
        }
        key(Key5; "Territory Code")
        {
        }
        key(Key6; "Salesperson Code")
        {
        }
        key(Key7; "VAT Registration No.")
        {
        }
        key(Key8; "Search E-Mail")
        {
        }
        key(Key9; Name)
        {
        }
        key(Key10; City)
        {
        }
        key(Key11; "Post Code")
        {
        }
        key(Key12; "Phone No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, Type, City, "Post Code", "Phone No.")
        {
        }
        fieldgroup(Brick; "No.", Name, Type, City, "Phone No.", Image)
        {
        }
    }

    trigger OnDelete()
    var
        Task: Record "To-do";
        SegLine: Record "Segment Line";
        ContIndustGrp: Record "Contact Industry Group";
        ContactWebSource: Record "Contact Web Source";
        ContJobResp: Record "Contact Job Responsibility";
        ContMailingGrp: Record "Contact Mailing Group";
        ContProfileAnswer: Record "Contact Profile Answer";
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        ContAltAddr: Record "Contact Alt. Address";
        ContAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        InteractLogEntry: Record "Interaction Log Entry";
        Opp: Record Opportunity;
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IntrastatSetup: Record "Intrastat Setup";
        CampaignTargetGrMgt: Codeunit "Campaign Target Group Mgt";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
    begin
        Task.SetCurrentKey("Contact Company No.", "Contact No.", Closed, Date);
        Task.SetRange("Contact Company No.", "Company No.");
        Task.SetRange("Contact No.", "No.");
        Task.SetRange(Closed, false);
        if Task.Find('-') then
            Error(CannotDeleteWithOpenTasksErr, "No.");

        SegLine.SetRange("Contact No.", "No.");
        if not SegLine.IsEmpty then
            Error(Text001, TableCaption, "No.");

        Opp.SetCurrentKey("Contact Company No.", "Contact No.");
        Opp.SetRange("Contact Company No.", "Company No.");
        Opp.SetRange("Contact No.", "No.");
        Opp.SetRange(Status, Opp.Status::"Not Started", Opp.Status::"In Progress");
        if Opp.Find('-') then
            Error(Text002, TableCaption, "No.");

        ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.DeleteAll();
        case Type of
            Type::Company:
                begin
                    ContIndustGrp.SetRange("Contact No.", "No.");
                    ContIndustGrp.DeleteAll();
                    ContactWebSource.SetRange("Contact No.", "No.");
                    ContactWebSource.DeleteAll();
                    DuplMgt.RemoveContIndex(Rec, false);
                    InteractLogEntry.SetCurrentKey("Contact Company No.");
                    InteractLogEntry.SetRange("Contact Company No.", "No.");
                    if InteractLogEntry.Find('-') then
                        repeat
                            CampaignTargetGrMgt.DeleteContfromTargetGr(InteractLogEntry);
                            Clear(InteractLogEntry."Contact Company No.");
                            Clear(InteractLogEntry."Contact No.");
                            InteractLogEntry.Modify();
                        until InteractLogEntry.Next = 0;

                    Cont.Reset();
                    Cont.SetCurrentKey("Company No.");
                    Cont.SetRange("Company No.", "No.");
                    Cont.SetRange(Type, Type::Person);
                    if Cont.Find('-') then
                        repeat
                            Cont.Delete(true);
                        until Cont.Next = 0;

                    Opp.Reset();
                    Opp.SetCurrentKey("Contact Company No.", "Contact No.");
                    Opp.SetRange("Contact Company No.", "Company No.");
                    Opp.SetRange("Contact No.", "No.");
                    if Opp.Find('-') then
                        repeat
                            Clear(Opp."Contact No.");
                            Clear(Opp."Contact Company No.");
                            Opp.Modify();
                        until Opp.Next = 0;

                    Task.Reset();
                    Task.SetCurrentKey("Contact Company No.");
                    Task.SetRange("Contact Company No.", "Company No.");
                    if Task.Find('-') then
                        repeat
                            Clear(Task."Contact No.");
                            Clear(Task."Contact Company No.");
                            Task.Modify();
                        until Task.Next = 0;
                end;
            Type::Person:
                begin
                    ContJobResp.SetRange("Contact No.", "No.");
                    if not ContJobResp.IsEmpty then
                        ContJobResp.DeleteAll();

                    InteractLogEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                    InteractLogEntry.SetRange("Contact Company No.", "Company No.");
                    InteractLogEntry.SetRange("Contact No.", "No.");
                    if not InteractLogEntry.IsEmpty then
                        InteractLogEntry.ModifyAll("Contact No.", "Company No.");

                    Opp.Reset();
                    Opp.SetCurrentKey("Contact Company No.", "Contact No.");
                    Opp.SetRange("Contact Company No.", "Company No.");
                    Opp.SetRange("Contact No.", "No.");
                    if not Opp.IsEmpty then
                        Opp.ModifyAll("Contact No.", "Company No.");

                    Task.Reset();
                    Task.SetCurrentKey("Contact Company No.", "Contact No.");
                    Task.SetRange("Contact Company No.", "Company No.");
                    Task.SetRange("Contact No.", "No.");
                    if not Task.IsEmpty then
                        Task.ModifyAll("Contact No.", "Company No.");
                end;
        end;

        ContMailingGrp.SetRange("Contact No.", "No.");
        if not ContMailingGrp.IsEmpty then
            ContMailingGrp.DeleteAll();

        ContProfileAnswer.SetRange("Contact No.", "No.");
        if not ContProfileAnswer.IsEmpty then
            ContProfileAnswer.DeleteAll();

        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::Contact);
        RMCommentLine.SetRange("No.", "No.");
        RMCommentLine.SetRange("Sub No.", 0);
        if not RMCommentLine.IsEmpty then
            RMCommentLine.DeleteAll();

        ContAltAddr.SetRange("Contact No.", "No.");
        if not ContAltAddr.IsEmpty then
            ContAltAddr.DeleteAll();

        ContAltAddrDateRange.SetRange("Contact No.", "No.");
        if not ContAltAddrDateRange.IsEmpty then
            ContAltAddrDateRange.DeleteAll();

        VATRegistrationLogMgt.DeleteContactLog(Rec);

        IntrastatSetup.CheckDeleteIntrastatContact(IntrastatSetup."Intrastat Contact Type"::Contact, "No.");
    end;

    trigger OnInsert()
    begin
        RMSetup.Get();

        if "No." = '' then begin
            RMSetup.TestField("Contact Nos.");
            NoSeriesMgt.InitSeries(RMSetup."Contact Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        if not SkipDefaults then begin
            if "Salesperson Code" = '' then begin
                "Salesperson Code" := RMSetup."Default Salesperson Code";
                SetDefaultSalesperson;
            end;
            if "Territory Code" = '' then
                "Territory Code" := RMSetup."Default Territory Code";
            if "Country/Region Code" = '' then
                "Country/Region Code" := RMSetup."Default Country/Region Code";
            if "Language Code" = '' then
                "Language Code" := RMSetup."Default Language Code";
            if "Correspondence Type" = "Correspondence Type"::" " then
                "Correspondence Type" := RMSetup."Default Correspondence Type";
            if "Salutation Code" = '' then
                if Type = Type::Company then
                    "Salutation Code" := RMSetup."Def. Company Salutation Code"
                else
                    "Salutation Code" := RMSetup."Default Person Salutation Code";
            OnAfterSetDefaults(Rec, RMSetup);
        end;

        TypeChange;
        SetLastDateTimeModified;
        SetSearchEmail();
    end;

    trigger OnModify()
    var
        ContactBeforeModify: Record Contact;
    begin
        // If the modify is called from code, Rec and xRec are the same,
        // so find the xRec
        ContactBeforeModify.Copy(xRec);
        if Format(xRec) = Format(Rec) then
            ContactBeforeModify.Find;
        DoModify(ContactBeforeModify);
        SetSearchEmail();
    end;

    trigger OnRename()
    begin
        Validate("Lookup Contact No.");
    end;

    var
        CannotDeleteWithOpenTasksErr: Label 'You cannot delete contact %1 because there are one or more tasks open.', Comment = '%1 = Contact No.';
        Text001: Label 'You cannot delete the %2 record of the %1 because the contact is assigned one or more unlogged segments.';
        Text002: Label 'You cannot delete the %2 record of the %1 because one or more opportunities are in not started or progress.';
        Text003: Label '%1 cannot be changed because one or more interaction log entries are linked to the contact.';
        CannotChangeWithOpenTasksErr: Label '%1 cannot be changed because one or more tasks are linked to the contact.', Comment = '%1 = Contact No.';
        Text006: Label '%1 cannot be changed because one or more opportunities are linked to the contact.';
        Text007: Label '%1 cannot be changed because there are one or more related people linked to the contact.';
        RelatedRecordIsCreatedMsg: Label 'The %1 record has been created.', Comment = 'The Customer record has been created.';
        Text010: Label 'The %2 record of the %1 is not linked with any other table.';
        RMSetup: Record "Marketing Setup";
        Salesperson: Record "Salesperson/Purchaser";
        PostCode: Record "Post Code";
        DuplMgt: Codeunit DuplicateManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        CampaignMgt: Codeunit "Campaign Target Group Mgt";
        ContChanged: Boolean;
        SkipDefaults: Boolean;
        Text012: Label 'You cannot change %1 because one or more unlogged segments are assigned to the contact.';
        Text019: Label 'The %2 record of the %1 already has the %3 with %4 %5.';
        CreateCustomerFromContactQst: Label 'Do you want to create a contact as a customer using a customer template?';
        Text021: Label 'You have to set up formal and informal salutation formulas in %1  language for the %2 contact.';
        Text022: Label 'The creation of the customer has been aborted.';
        Text033: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
        SelectContactErr: Label 'You must select an existing contact.';
        AlreadyExistErr: Label '%1 %2 already has a %3 with %4 %5.', Comment = '%1=Contact table caption;%2=Contact number;%3=Contact Business Relation table caption;%4=Contact Business Relation Link to Table value;%5=Contact Business Relation number';
        HideValidationDialog: Boolean;
        PrivacyBlockedPostErr: Label 'You cannot post this type of document because contact %1 is blocked due to privacy.', Comment = '%1=contact no.';
        PrivacyBlockedCreateErr: Label 'You cannot create this type of document because contact %1 is blocked due to privacy.', Comment = '%1=contact no.';
        PrivacyBlockedGenericErr: Label 'You cannot use contact %1 %2 because they are marked as blocked due to privacy.', Comment = '%1=contact no.;%2=contact name';
        ParentalConsentReceivedErr: Label 'Privacy Blocked cannot be cleared until Parental Consent Received is set to true for minor contact %1.', Comment = '%1=contact no.';
        ProfileForMinorErr: Label 'You cannot use profiles for contacts marked as Minor.';
        MultipleCustomerTemplatesConfirmQst: Label 'Quotes with customer templates different from %1 were assigned to customer %2. Do you want to review the quotes now?', Comment = '%1=Customer Template Code,%2=Customer No.';
        DifferentCustomerTemplateMsg: Label 'Sales quote %1 with original customer template %2 was assigned to the customer created from template %3.', Comment = '%1=Document No.,%2=Original Customer Template Code,%3=Customer Template Code';
        NoOriginalCustomerTemplateMsg: Label 'Sales quote %1 without an original customer template was assigned to the customer created from template %2.', Comment = '%1=Document No.,%2=Customer Template Code';

    procedure DoModify(ContactBeforeModify: Record Contact)
    var
        OldCont: Record Contact;
        Cont: Record Contact;
        IsDuplicateCheckNeeded: Boolean;
    begin
        SetLastDateTimeModified;

        if "No." <> '' then
            if IsUpdateNeeded then
                UpdateCustVendBank.Run(Rec);

        if Type = Type::Company then begin
            RMSetup.Get();
            Cont.Reset();
            Cont.SetCurrentKey("Company No.");
            Cont.SetRange("Company No.", "No.");
            Cont.SetRange(Type, Type::Person);
            Cont.SetFilter("No.", '<>%1', "No.");
            if Cont.Find('-') then
                repeat
                    ContChanged := false;
                    OldCont := Cont;
                    if Name <> ContactBeforeModify.Name then begin
                        Cont."Company Name" := Name;
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Salesperson Code" and
                       (ContactBeforeModify."Salesperson Code" <> "Salesperson Code") and
                       (ContactBeforeModify."Salesperson Code" = Cont."Salesperson Code")
                    then begin
                        Cont."Salesperson Code" := "Salesperson Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Territory Code" and
                       (ContactBeforeModify."Territory Code" <> "Territory Code") and
                       (ContactBeforeModify."Territory Code" = Cont."Territory Code")
                    then begin
                        Cont."Territory Code" := "Territory Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Country/Region Code" and
                       (ContactBeforeModify."Country/Region Code" <> "Country/Region Code") and
                       (ContactBeforeModify."Country/Region Code" = Cont."Country/Region Code")
                    then begin
                        Cont."Country/Region Code" := "Country/Region Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Language Code" and
                       (ContactBeforeModify."Language Code" <> "Language Code") and
                       (ContactBeforeModify."Language Code" = Cont."Language Code")
                    then begin
                        Cont."Language Code" := "Language Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Address Details" then
                        if ContactBeforeModify.IdenticalAddress(Cont) then begin
                            if ContactBeforeModify.Address <> Address then begin
                                Cont.Address := Address;
                                ContChanged := true;
                            end;
                            if ContactBeforeModify."Address 2" <> "Address 2" then begin
                                Cont."Address 2" := "Address 2";
                                ContChanged := true;
                            end;
                            if ContactBeforeModify."Post Code" <> "Post Code" then begin
                                Cont."Post Code" := "Post Code";
                                ContChanged := true;
                            end;
                            if ContactBeforeModify.City <> City then begin
                                Cont.City := City;
                                ContChanged := true;
                            end;
                            if ContactBeforeModify.County <> County then begin
                                Cont.County := County;
                                ContChanged := true;
                            end;
                            OnAfterSyncAddress(Cont, Rec, ContChanged);
                        end;
                    if RMSetup."Inherit Communication Details" then begin
                        if (ContactBeforeModify."Phone No." <> "Phone No.") and (ContactBeforeModify."Phone No." = Cont."Phone No.") then begin
                            Cont."Phone No." := "Phone No.";
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify."Telex No." <> "Telex No.") and (ContactBeforeModify."Telex No." = Cont."Telex No.") then begin
                            Cont."Telex No." := "Telex No.";
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify."Fax No." <> "Fax No.") and (ContactBeforeModify."Fax No." = Cont."Fax No.") then begin
                            Cont."Fax No." := "Fax No.";
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify."Telex Answer Back" <> "Telex Answer Back") and (ContactBeforeModify."Telex Answer Back" = Cont."Telex Answer Back") then begin
                            Cont."Telex Answer Back" := "Telex Answer Back";
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify."E-Mail" <> "E-Mail") and (ContactBeforeModify."E-Mail" = Cont."E-Mail") then begin
                            Cont.Validate("E-Mail", "E-Mail");
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify."Home Page" <> "Home Page") and (ContactBeforeModify."Home Page" = Cont."Home Page") then begin
                            Cont."Home Page" := "Home Page";
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify."Extension No." <> "Extension No.") and (ContactBeforeModify."Extension No." = Cont."Extension No.") then begin
                            Cont."Extension No." := "Extension No.";
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify."Mobile Phone No." <> "Mobile Phone No.") and (ContactBeforeModify."Mobile Phone No." = Cont."Mobile Phone No.") then begin
                            Cont."Mobile Phone No." := "Mobile Phone No.";
                            ContChanged := true;
                        end;
                        if (ContactBeforeModify.Pager <> Pager) and (ContactBeforeModify.Pager = Cont.Pager) then begin
                            Cont.Pager := Pager;
                            ContChanged := true;
                        end;
                    end;

                    OnBeforeApplyCompanyChangeToPerson(Cont, Rec, ContactBeforeModify, ContChanged, OldCont);
                    if ContChanged then begin
                        Cont.DoModify(OldCont);
                        Cont.Modify();
                    end;
                until Cont.Next = 0;

            IsDuplicateCheckNeeded :=
              (Name <> ContactBeforeModify.Name) or
              ("Name 2" <> ContactBeforeModify."Name 2") or
              (Address <> ContactBeforeModify.Address) or
              ("Address 2" <> ContactBeforeModify."Address 2") or
              (City <> ContactBeforeModify.City) or
              ("Post Code" <> ContactBeforeModify."Post Code") or
              ("VAT Registration No." <> ContactBeforeModify."VAT Registration No.") or
              ("Phone No." <> ContactBeforeModify."Phone No.");

            OnBeforeDuplicateCheck(Rec, ContactBeforeModify, IsDuplicateCheckNeeded);

            if IsDuplicateCheckNeeded then
                CheckDuplicates;
        end;

        OnAfterOnModify(Rec, ContactBeforeModify);
    end;

    procedure TypeChange()
    var
        InteractLogEntry: Record "Interaction Log Entry";
        Opp: Record Opportunity;
        Task: Record "To-do";
        Cont: Record Contact;
        CampaignTargetGrMgt: Codeunit "Campaign Target Group Mgt";
    begin
        RMSetup.Get();

        if Type <> xRec.Type then begin
            InteractLogEntry.LockTable();
            Cont.LockTable();
            InteractLogEntry.SetCurrentKey("Contact Company No.", "Contact No.");
            InteractLogEntry.SetRange("Contact Company No.", "Company No.");
            InteractLogEntry.SetRange("Contact No.", "No.");
            if InteractLogEntry.FindFirst then
                Error(Text003, FieldCaption(Type));
            OnTypeChangeOnAfterCheckInteractionLog(Rec, xRec);
            Task.SetRange("Contact Company No.", "Company No.");
            Task.SetRange("Contact No.", "No.");
            if not Task.IsEmpty then
                Error(CannotChangeWithOpenTasksErr, FieldCaption(Type));
            Opp.SetRange("Contact Company No.", "Company No.");
            Opp.SetRange("Contact No.", "No.");
            if not Opp.IsEmpty then
                Error(Text006, FieldCaption(Type));
        end;

        case Type of
            Type::Company:
                begin
                    if Type <> xRec.Type then begin
                        TestField("Organizational Level Code", '');
                        TestField("No. of Job Responsibilities", 0);
                    end;
                    "First Name" := '';
                    "Middle Name" := '';
                    Surname := '';
                    "Job Title" := '';
                    "Company No." := "No.";
                    "Company Name" := Name;
                    "Salutation Code" := RMSetup."Def. Company Salutation Code";
                end;
            Type::Person:
                begin
                    CampaignTargetGrMgt.DeleteContfromTargetGr(InteractLogEntry);
                    Cont.Reset();
                    Cont.SetCurrentKey("Company No.");
                    Cont.SetRange("Company No.", "No.");
                    Cont.SetRange(Type, Type::Person);
                    if Cont.FindFirst then
                        Error(Text007, FieldCaption(Type));
                    if Type <> xRec.Type then begin
                        CalcFields("No. of Business Relations", "No. of Industry Groups");
                        TestField("No. of Business Relations", 0);
                        TestField("No. of Industry Groups", 0);
                        TestField("Currency Code", '');
                        TestField("VAT Registration No.", '');
                    end;
                    if "Company No." = "No." then begin
                        "Company No." := '';
                        "Company Name" := '';
                        "Salutation Code" := RMSetup."Default Person Salutation Code";
                        NameBreakdown;
                    end;
                end;
        end;
        OnAfterSetTypeForContact(Rec);
        Validate("Lookup Contact No.");

        if Cont.Get("No.") then begin
            if Type = Type::Company then
                CheckDuplicates
            else
                DuplMgt.RemoveContIndex(Rec, false);
        end;
    end;

    procedure AssistEdit(OldCont: Record Contact) Result: Boolean
    var
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldCont, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with Cont do begin
            Cont := Rec;
            RMSetup.Get();
            RMSetup.TestField("Contact Nos.");
            if NoSeriesMgt.SelectSeries(RMSetup."Contact Nos.", OldCont."No. Series", "No. Series") then begin
                RMSetup.Get();
                RMSetup.TestField("Contact Nos.");
                NoSeriesMgt.SetSeries("No.");
                Rec := Cont;
                exit(true);
            end;
        end;
    end;

    procedure CreateCustomer(CustomerTemplate: Code[10]) CustNo: Code[20]
    var
        Cust: Record Customer;
        CustTemplate: Record "Customer Template";
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        ContBusRel: Record "Contact Business Relation";
        OfficeMgt: Codeunit "Office Management";
    begin
        CheckForExistingRelationships(ContBusRel."Link to Table"::Customer);
        CheckIfPrivacyBlockedGeneric;
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Customers");

        if CustomerTemplate <> '' then
            if CustTemplate.Get(CustomerTemplate) then;

        Clear(Cust);
        Cust.SetInsertFromContact(true);
        Cust."Contact Type" := Type;
        OnBeforeCustomerInsert(Cust, CustomerTemplate, Rec);
        Cust.Insert(true);
        Cust.SetInsertFromContact(false);
        CustNo := Cust."No.";

        ContBusRel."Contact No." := "No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Customer;
        ContBusRel."No." := Cust."No.";
        ContBusRel.Insert(true);

        UpdateCustVendBank.UpdateCustomer(Rec, ContBusRel);

        Cust.Get(ContBusRel."No.");
        if Type = Type::Company then
            Cust.Validate(Name, "Company Name");

        OnCreateCustomerOnBeforeCustomerModify(Cust, Rec);
        Cust.Modify();

        if CustTemplate.Code <> '' then begin
            if "Territory Code" = '' then
                Cust."Territory Code" := CustTemplate."Territory Code"
            else
                Cust."Territory Code" := "Territory Code";
            if "Currency Code" = '' then
                Cust."Currency Code" := CustTemplate."Currency Code"
            else
                Cust."Currency Code" := "Currency Code";
            if "Country/Region Code" = '' then
                Cust."Country/Region Code" := CustTemplate."Country/Region Code"
            else
                Cust."Country/Region Code" := "Country/Region Code";
            Cust."Customer Posting Group" := CustTemplate."Customer Posting Group";
            Cust."Customer Price Group" := CustTemplate."Customer Price Group";
            if CustTemplate."Invoice Disc. Code" <> '' then
                Cust."Invoice Disc. Code" := CustTemplate."Invoice Disc. Code";
            Cust."Customer Disc. Group" := CustTemplate."Customer Disc. Group";
            Cust."Allow Line Disc." := CustTemplate."Allow Line Disc.";
            Cust."Gen. Bus. Posting Group" := CustTemplate."Gen. Bus. Posting Group";
            Cust."VAT Bus. Posting Group" := CustTemplate."VAT Bus. Posting Group";
            Cust."Payment Terms Code" := CustTemplate."Payment Terms Code";
            Cust."Payment Method Code" := CustTemplate."Payment Method Code";
            Cust."Prices Including VAT" := CustTemplate."Prices Including VAT";
            Cust."Shipment Method Code" := CustTemplate."Shipment Method Code";
            Cust.UpdateReferencedIds;
            OnCreateCustomerOnTransferFieldsFromTemplate(Cust, CustTemplate);
            Cust.Modify();

            DefaultDim.SetRange("Table ID", DATABASE::"Customer Template");
            DefaultDim.SetRange("No.", CustTemplate.Code);
            if DefaultDim.Find('-') then
                repeat
                    Clear(DefaultDim2);
                    DefaultDim2.Init();
                    DefaultDim2.Validate("Table ID", DATABASE::Customer);
                    DefaultDim2."No." := Cust."No.";
                    DefaultDim2.Validate("Dimension Code", DefaultDim."Dimension Code");
                    DefaultDim2.Validate("Dimension Value Code", DefaultDim."Dimension Value Code");
                    DefaultDim2."Value Posting" := DefaultDim."Value Posting";
                    DefaultDim2.Insert(true);
                until DefaultDim.Next = 0;
        end;

        OnCreateCustomerOnBeforeUpdateQuotes(Cust, Rec);

        UpdateQuotes(Cust, CustomerTemplate);
        CampaignMgt.ConverttoCustomer(Rec, Cust);
        if OfficeMgt.IsAvailable then
            PAGE.Run(PAGE::"Customer Card", Cust)
        else
            if not HideValidationDialog then
                Message(RelatedRecordIsCreatedMsg, Cust.TableCaption);

        OnAfterCreateCustomer(Rec, Cust);
    end;

    procedure CreateVendor() VendorNo: Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
        Vend: Record Vendor;
        ContComp: Record Contact;
        OfficeMgt: Codeunit "Office Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateVendor(Rec, VendorNo, IsHandled);
        if IsHandled then
            exit;

        CheckForExistingRelationships(ContBusRel."Link to Table"::Vendor);
        CheckIfPrivacyBlockedGeneric;
        CheckCompanyNo;
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Vendors");

        Clear(Vend);
        Vend.SetInsertFromContact(true);
        OnBeforeVendorInsert(Vend, Rec);
        Vend.Insert(true);
        Vend.SetInsertFromContact(false);
        VendorNo := Vend."No.";

        if Type = Type::Company then
            ContComp := Rec
        else
            ContComp.Get("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Vendor;
        ContBusRel."No." := Vend."No.";
        ContBusRel.Insert(true);

        OnAfterVendorInsert(Vend, Rec);

        UpdateCustVendBank.UpdateVendor(ContComp, ContBusRel);

        OnCreateVendorOnAfterUpdateVendor(Vend, Rec);

        if OfficeMgt.IsAvailable then
            PAGE.Run(PAGE::"Vendor Card", Vend)
        else
            if not HideValidationDialog then
                Message(RelatedRecordIsCreatedMsg, Vend.TableCaption);

        OnAfterCreateVendor(Rec, Vend);
    end;

    procedure CreateBankAccount()
    var
        BankAcc: Record "Bank Account";
        ContComp: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        TestField("Company No.");
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Bank Accs.");

        Clear(BankAcc);
        BankAcc.SetInsertFromContact(true);
        OnBeforeBankAccountInsert(BankAcc);
        BankAcc.Insert(true);
        BankAcc.SetInsertFromContact(false);

        if Type = Type::Company then
            ContComp := Rec
        else
            ContComp.Get("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Bank Accs.";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::"Bank Account";
        ContBusRel."No." := BankAcc."No.";
        ContBusRel.Insert(true);

        CheckIfPrivacyBlockedGeneric;

        UpdateCustVendBank.UpdateBankAccount(ContComp, ContBusRel);

        if not HideValidationDialog then
            Message(RelatedRecordIsCreatedMsg, BankAcc.TableCaption);
    end;

    procedure CreateCustomerLink()
    var
        Cust: Record Customer;
        ContBusRel: Record "Contact Business Relation";
    begin
        CheckForExistingRelationships(ContBusRel."Link to Table"::Customer);
        CheckIfPrivacyBlockedGeneric;
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Customers");
        CreateLink(
          PAGE::"Customer Link",
          RMSetup."Bus. Rel. Code for Customers",
          ContBusRel."Link to Table"::Customer);

        ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("Contact No.", "Company No.");
        if ContBusRel.FindFirst then
            if Cust.Get(ContBusRel."No.") then
                UpdateQuotes(Cust, '');
    end;

    procedure CreateVendorLink()
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        CheckForExistingRelationships(ContBusRel."Link to Table"::Vendor);
        CheckIfPrivacyBlockedGeneric;
        TestField("Company No.");
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Vendors");
        CreateLink(
          PAGE::"Vendor Link",
          RMSetup."Bus. Rel. Code for Vendors",
          ContBusRel."Link to Table"::Vendor);
    end;

    procedure CreateBankAccountLink()
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        CheckIfPrivacyBlockedGeneric;
        TestField("Company No.");
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Bank Accs.");
        CreateLink(
          PAGE::"Bank Account Link",
          RMSetup."Bus. Rel. Code for Bank Accs.",
          ContBusRel."Link to Table"::"Bank Account");
    end;

    local procedure CreateLink(CreateForm: Integer; BusRelCode: Code[10]; "Table": Enum "Contact Business Relation Link To Table")
    var
        TempContBusRel: Record "Contact Business Relation" temporary;
    begin
        OnBeforeCreateLink(Rec, TempContBusRel, CreateForm, BusRelCode, Table);
        TempContBusRel."Contact No." := "No.";
        TempContBusRel."Business Relation Code" := BusRelCode;
        TempContBusRel."Link to Table" := Table;
        TempContBusRel.Insert();
        if PAGE.RunModal(CreateForm, TempContBusRel) = ACTION::LookupOK then; // enforce look up mode dialog
        TempContBusRel.DeleteAll();
    end;

    procedure CreateInteraction()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        CheckIfPrivacyBlockedGeneric;
        TempSegmentLine.CreateInteractionFromContact(Rec);
    end;

    procedure GetDefaultPhoneNo(): Text[30]
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone then begin
            if "Mobile Phone No." = '' then
                exit("Phone No.");
            exit("Mobile Phone No.");
        end;
        if "Phone No." = '' then
            exit("Mobile Phone No.");
        exit("Phone No.");
    end;

    procedure ShowCustVendBank()
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FormSelected: Boolean;
        IsHandled: Boolean;
    begin
        FormSelected := true;

        ContBusRel.Reset();

        if "Company No." <> '' then
            ContBusRel.SetFilter("Contact No.", '%1|%2', "No.", "Company No.")
        else
            ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.SetFilter("No.", '<>''''');

        case ContBusRel.Count of
            0:
                Error(Text010, TableCaption, "No.");
            1:
                ContBusRel.FindFirst;
            else
                FormSelected := PAGE.RunModal(PAGE::"Contact Business Relations", ContBusRel) = ACTION::LookupOK;
        end;

        IsHandled := false;
        OnShowCustVendBankOnBeforeRunPage(Rec, FormSelected, ContBusRel, IsHandled);
        if IsHandled THEN
            exit;

        if FormSelected then
            case ContBusRel."Link to Table" of
                ContBusRel."Link to Table"::Customer:
                    begin
                        Cust.Get(ContBusRel."No.");
                        PAGE.Run(PAGE::"Customer Card", Cust);
                    end;
                ContBusRel."Link to Table"::Vendor:
                    begin
                        Vend.Get(ContBusRel."No.");
                        PAGE.Run(PAGE::"Vendor Card", Vend);
                    end;
                ContBusRel."Link to Table"::"Bank Account":
                    begin
                        BankAcc.Get(ContBusRel."No.");
                        PAGE.Run(PAGE::"Bank Account Card", BankAcc);
                    end;
                else
                    OnShowCustVendBankCaseElse(ContBusRel);
            end;

        OnAfterShowCustVendBank(Rec, ContBusRel, FormSelected);
    end;

    local procedure NameBreakdown()
    var
        NamePart: array[30] of Text[100];
        TempName: Text[250];
        FirstName250: Text[250];
        i: Integer;
        NoOfParts: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNameBreakdown(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Company then
            exit;

        TempName := Name;
        while StrPos(TempName, ' ') > 0 do begin
            if StrPos(TempName, ' ') > 1 then begin
                i := i + 1;
                NamePart[i] := CopyStr(TempName, 1, StrPos(TempName, ' ') - 1);
            end;
            TempName := CopyStr(TempName, StrPos(TempName, ' ') + 1);
        end;
        i := i + 1;
        NamePart[i] := CopyStr(TempName, 1, MaxStrLen(NamePart[i]));
        NoOfParts := i;

        "First Name" := '';
        "Middle Name" := '';
        Surname := '';
        for i := 1 to NoOfParts do
            if (i = NoOfParts) and (NoOfParts > 1) then
                Surname := CopyStr(NamePart[i], 1, MaxStrLen(Surname))
            else
                if (i = NoOfParts - 1) and (NoOfParts > 2) then
                    "Middle Name" := CopyStr(NamePart[i], 1, MaxStrLen("Middle Name"))
                else begin
                    FirstName250 := DelChr("First Name" + ' ' + NamePart[i], '<', ' ');
                    "First Name" := CopyStr(FirstName250, 1, MaxStrLen("First Name"));
                end;
    end;

    procedure SetSkipDefault()
    begin
        SkipDefaults := true;
    end;

    procedure IdenticalAddress(Cont: Record Contact) IsIdentical: Boolean
    begin
        IsIdentical :=
          (Address = Cont.Address) and
          ("Address 2" = Cont."Address 2") and
          ("Post Code" = Cont."Post Code") and
          (City = Cont.City);

        OnAfterIdenticalAddress(Cont, Rec, IsIdentical);
    end;

    procedure ActiveAltAddress(ActiveDate: Date): Code[10]
    var
        ContAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
    begin
        ContAltAddrDateRange.SetCurrentKey("Contact No.", "Starting Date");
        ContAltAddrDateRange.SetRange("Contact No.", "No.");
        ContAltAddrDateRange.SetRange("Starting Date", 0D, ActiveDate);
        ContAltAddrDateRange.SetFilter("Ending Date", '>=%1|%2', ActiveDate, 0D);
        if ContAltAddrDateRange.FindLast then
            exit(ContAltAddrDateRange."Contact Alt. Address Code");

        exit('');
    end;

    procedure CalculatedName() NewName: Text[100]
    var
        NewName92: Text[92];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatedName(Rec, NewName, IsHandled);
        if IsHandled then
            exit(NewName);

        if "First Name" <> '' then
            NewName92 := "First Name";
        if "Middle Name" <> '' then
            NewName92 := NewName92 + ' ' + "Middle Name";
        if Surname <> '' then
            NewName92 := NewName92 + ' ' + Surname;

        NewName92 := DelChr(NewName92, '<', ' ');

        OnAfterCalculatedName(Rec, NewName92);
        NewName := CopyStr(NewName92, 1, MaxStrLen(NewName));
    end;

    local procedure UpdateSearchName()
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateSearchName(Rec, xRec, IsHandled);
        if IsHandled then
            exit;
        if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
            "Search Name" := Name;
    end;

    local procedure CheckDuplicates()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckDuplicates(Rec, IsHandled);
        if IsHandled then
            exit;

        if RMSetup."Maintain Dupl. Search Strings" then
            DuplMgt.MakeContIndex(Rec);

        if not GuiAllowed then
            exit;

        IsHandled := false;
        OnBeforeLaunchDuplicateForm(Rec, IsHandled);
        if not IsHandled then
            if DuplMgt.DuplicateExist(Rec) then begin
                Modify;
                Commit();
                DuplMgt.LaunchDuplicateForm(Rec);
            end;
    end;

    local procedure CheckCompanyNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCompanyNo(Rec, IsHandled);
        if not IsHandled then
            TestField("Company No.");
    end;

    procedure FindCustomerTemplate(): Code[10]
    var
        CustTemplate: Record "Customer Template";
        ContCompany: Record Contact;
        CustTemplateCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindCustomerTemplate(Rec, CustTemplateCode, IsHandled);
        if IsHandled then
            exit(CustTemplateCode);

        CustTemplate.Reset();
        CustTemplate.SetRange("Territory Code", "Territory Code");
        CustTemplate.SetRange("Country/Region Code", "Country/Region Code");
        CustTemplate.SetRange("Contact Type", Type);
        if ContCompany.Get("Company No.") then
            CustTemplate.SetRange("Currency Code", ContCompany."Currency Code");

        if CustTemplate.Count = 1 then begin
            CustTemplate.FindFirst;
            exit(CustTemplate.Code);
        end;
    end;

    procedure ChooseCustomerTemplate(): Code[10]
    var
        CustTemplate: Record "Customer Template";
        ContBusRel: Record "Contact Business Relation";
        CustTemplateCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChooseCustomerTemplate(Rec, CustTemplateCode, IsHandled);
        if IsHandled then
            exit(CustTemplateCode);

        CheckForExistingRelationships(ContBusRel."Link to Table"::Customer);
        ContBusRel.Reset();
        ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        if ContBusRel.FindFirst then
            Error(
              Text019,
              TableCaption, "No.", ContBusRel.TableCaption, ContBusRel."Link to Table", ContBusRel."No.");

        if Confirm(CreateCustomerFromContactQst, true) then begin
            CustTemplate.SetRange("Contact Type", Type);
            if PAGE.RunModal(0, CustTemplate) = ACTION::LookupOK then
                exit(CustTemplate.Code);

            Error(Text022);
        end;
    end;

    local procedure UpdateCompanyNo()
    var
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        InteractLogEntry: Record "Interaction Log Entry";
        Opp: Record Opportunity;
        OppEntry: Record "Opportunity Entry";
        SalesHeader: Record "Sales Header";
        Task: Record "To-do";
    begin
        OnBeforeUpdateCompanyNo(Rec, xRec);
        if Cont.Get("No.") then begin
            if xRec."Company No." <> '' then begin
                Opp.SetCurrentKey("Contact Company No.", "Contact No.");
                Opp.SetRange("Contact Company No.", xRec."Company No.");
                Opp.SetRange("Contact No.", "No.");
                if not Opp.IsEmpty then
                    Opp.ModifyAll("Contact No.", xRec."Company No.");
                OppEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                OppEntry.SetRange("Contact Company No.", xRec."Company No.");
                OppEntry.SetRange("Contact No.", "No.");
                if not OppEntry.IsEmpty then
                    OppEntry.ModifyAll("Contact No.", xRec."Company No.");
                Task.SetCurrentKey("Contact Company No.", "Contact No.");
                Task.SetRange("Contact Company No.", xRec."Company No.");
                Task.SetRange("Contact No.", "No.");
                if not Task.IsEmpty then
                    Task.ModifyAll("Contact No.", xRec."Company No.");
                InteractLogEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                InteractLogEntry.SetRange("Contact Company No.", xRec."Company No.");
                InteractLogEntry.SetRange("Contact No.", "No.");
                if not InteractLogEntry.IsEmpty then
                    InteractLogEntry.ModifyAll("Contact No.", xRec."Company No.");
                ContBusRel.Reset();
                ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("Contact No.", xRec."Company No.");
                SalesHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                SalesHeader.SetRange("Sell-to Contact No.", "No.");
                if ContBusRel.FindFirst then
                    SalesHeader.SetRange("Sell-to Customer No.", ContBusRel."No.")
                else
                    SalesHeader.SetRange("Sell-to Customer No.", '');
                if SalesHeader.Find('-') then
                    repeat
                        SalesHeader."Sell-to Contact No." := xRec."Company No.";
                        if SalesHeader."Sell-to Contact No." = SalesHeader."Bill-to Contact No." then
                            SalesHeader."Bill-to Contact No." := xRec."Company No.";
                        SalesHeader.Modify();
                    until SalesHeader.Next = 0;
                SalesHeader.Reset();
                SalesHeader.SetCurrentKey("Bill-to Contact No.");
                SalesHeader.SetRange("Bill-to Contact No.", "No.");
                if not SalesHeader.IsEmpty then
                    SalesHeader.ModifyAll("Bill-to Contact No.", xRec."Company No.");
            end else begin
                Opp.SetCurrentKey("Contact Company No.", "Contact No.");
                Opp.SetRange("Contact Company No.", '');
                Opp.SetRange("Contact No.", "No.");
                if not Opp.IsEmpty then
                    Opp.ModifyAll("Contact Company No.", "Company No.");
                OppEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                OppEntry.SetRange("Contact Company No.", '');
                OppEntry.SetRange("Contact No.", "No.");
                if not OppEntry.IsEmpty then
                    OppEntry.ModifyAll("Contact Company No.", "Company No.");
                Task.SetCurrentKey("Contact Company No.", "Contact No.");
                Task.SetRange("Contact Company No.", '');
                Task.SetRange("Contact No.", "No.");
                if not Task.IsEmpty then
                    Task.ModifyAll("Contact Company No.", "Company No.");
                InteractLogEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                InteractLogEntry.SetRange("Contact Company No.", '');
                InteractLogEntry.SetRange("Contact No.", "No.");
                if not InteractLogEntry.IsEmpty then
                    InteractLogEntry.ModifyAll("Contact Company No.", "Company No.");
            end;

            if CurrFieldNo <> 0 then
                Modify;
        end;
    end;

    local procedure UpdateQuotes(Customer: Record Customer; CustomerTemplate: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Cont: Record Contact;
        SalesLine: Record "Sales Line";
        TempErrorMessage: Record "Error Message" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if "Company No." <> '' then
            Cont.SetRange("Company No.", "Company No.")
        else
            Cont.SetRange("No.", "No.");

        if Cont.FindSet then
            repeat
                SalesHeader.Reset();
                SalesHeader.SetRange("Sell-to Customer No.", '');
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
                SalesHeader.SetRange("Sell-to Contact No.", Cont."No.");
                if SalesHeader.FindSet then
                    repeat
                        SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.");
                        SalesHeader2."Sell-to Customer No." := Customer."No.";
                        SalesHeader2."Sell-to Customer Name" := Customer.Name;
                        CheckCustomerTemplate(SalesHeader2, TempErrorMessage, CustomerTemplate);
                        SalesHeader2."Sell-to Customer Template Code" := '';
                        if SalesHeader2."Sell-to Contact No." = SalesHeader2."Bill-to Contact No." then begin
                            SalesHeader2."Bill-to Customer No." := Customer."No.";
                            SalesHeader2."Bill-to Name" := Customer.Name;
                            SalesHeader2."Bill-to Customer Template Code" := '';
                            SalesHeader2."Salesperson Code" := Customer."Salesperson Code";
                        end;
                        SalesHeader2.Modify();
                        SalesLine.SetRange("Document Type", SalesHeader2."Document Type");
                        SalesLine.SetRange("Document No.", SalesHeader2."No.");
                        SalesLine.ModifyAll("Sell-to Customer No.", SalesHeader2."Sell-to Customer No.");
                        if SalesHeader2."Sell-to Contact No." = SalesHeader2."Bill-to Contact No." then
                            SalesLine.ModifyAll("Bill-to Customer No.", SalesHeader2."Bill-to Customer No.");
                        OnAfterModifySellToCustomerNo(SalesHeader2, SalesLine);
                    until SalesHeader.Next = 0;

                SalesHeader.Reset();
                SalesHeader.SetRange("Bill-to Customer No.", '');
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
                SalesHeader.SetRange("Bill-to Contact No.", Cont."No.");
                if SalesHeader.FindSet then
                    repeat
                        SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.");
                        SalesHeader2."Bill-to Customer No." := Customer."No.";
                        SalesHeader2."Bill-to Customer Template Code" := '';
                        SalesHeader2."Salesperson Code" := Customer."Salesperson Code";
                        SalesHeader2.Modify();
                        SalesLine.SetRange("Document Type", SalesHeader2."Document Type");
                        SalesLine.SetRange("Document No.", SalesHeader2."No.");
                        SalesLine.ModifyAll("Bill-to Customer No.", SalesHeader2."Bill-to Customer No.");
                        OnAfterModifyBillToCustomerNo(SalesHeader2, SalesLine);
                    until SalesHeader.Next = 0;
                OnAfterUpdateQuotesForContact(Cont, Customer);
            until Cont.Next = 0;

        if not TempErrorMessage.IsEmpty then
            if ConfirmManagement.GetResponse(
                 StrSubstNo(MultipleCustomerTemplatesConfirmQst, CustomerTemplate, Customer."No."), true)
            then
                TempErrorMessage.ShowErrorMessages(false);
    end;

    local procedure CheckCustomerTemplate(SalesHeader: Record "Sales Header"; var TempErrorMessage: Record "Error Message" temporary; CustomerTemplateCode: Code[10])
    var
        WarningMessage: Text;
    begin
        if CustomerTemplateCode = '' then
            exit;
        if SalesHeader."Sell-to Customer Template Code" <> CustomerTemplateCode then begin
            if SalesHeader."Sell-to Customer Template Code" <> '' then
                WarningMessage := StrSubstNo(
                    DifferentCustomerTemplateMsg,
                    SalesHeader."No.",
                    SalesHeader."Sell-to Customer Template Code",
                    CustomerTemplateCode)
            else
                WarningMessage := StrSubstNo(
                    NoOriginalCustomerTemplateMsg,
                    SalesHeader."No.",
                    CustomerTemplateCode);

            TempErrorMessage.LogMessage(
              SalesHeader,
              SalesHeader.FieldNo("Sell-to Customer Template Code"),
              TempErrorMessage."Message Type"::Warning,
              WarningMessage);
        end;
    end;

    procedure GetSalutation(SalutationType: Option Formal,Informal; LanguageCode: Code[10]) Salutation: Text[260]
    var
        SalutationFormula: Record "Salutation Formula";
        NamePart: array[5] of Text[100];
        IsHandled: Boolean;
    begin
        OnBeforeGetSalutation(Rec, SalutationType, LanguageCode, IsHandled, Salutation);
        IF IsHandled THEN
            exit(Salutation);

        if not SalutationFormula.Get("Salutation Code", LanguageCode, SalutationType) then
            Error(Text021, LanguageCode, "No.");
        SalutationFormula.TestField(Salutation);

        case SalutationFormula."Name 1" of
            SalutationFormula."Name 1"::"Job Title":
                NamePart[1] := "Job Title";
            SalutationFormula."Name 1"::"First Name":
                NamePart[1] := "First Name";
            SalutationFormula."Name 1"::"Middle Name":
                NamePart[1] := "Middle Name";
            SalutationFormula."Name 1"::Surname:
                NamePart[1] := Surname;
            SalutationFormula."Name 1"::Initials:
                NamePart[1] := Initials;
            SalutationFormula."Name 1"::"Company Name":
                NamePart[1] := "Company Name";
        end;

        case SalutationFormula."Name 2" of
            SalutationFormula."Name 2"::"Job Title":
                NamePart[2] := "Job Title";
            SalutationFormula."Name 2"::"First Name":
                NamePart[2] := "First Name";
            SalutationFormula."Name 2"::"Middle Name":
                NamePart[2] := "Middle Name";
            SalutationFormula."Name 2"::Surname:
                NamePart[2] := Surname;
            SalutationFormula."Name 2"::Initials:
                NamePart[2] := Initials;
            SalutationFormula."Name 2"::"Company Name":
                NamePart[2] := "Company Name";
        end;

        case SalutationFormula."Name 3" of
            SalutationFormula."Name 3"::"Job Title":
                NamePart[3] := "Job Title";
            SalutationFormula."Name 3"::"First Name":
                NamePart[3] := "First Name";
            SalutationFormula."Name 3"::"Middle Name":
                NamePart[3] := "Middle Name";
            SalutationFormula."Name 3"::Surname:
                NamePart[3] := Surname;
            SalutationFormula."Name 3"::Initials:
                NamePart[3] := Initials;
            SalutationFormula."Name 3"::"Company Name":
                NamePart[3] := "Company Name";
        end;

        case SalutationFormula."Name 4" of
            SalutationFormula."Name 4"::"Job Title":
                NamePart[4] := "Job Title";
            SalutationFormula."Name 4"::"First Name":
                NamePart[4] := "First Name";
            SalutationFormula."Name 4"::"Middle Name":
                NamePart[4] := "Middle Name";
            SalutationFormula."Name 4"::Surname:
                NamePart[4] := Surname;
            SalutationFormula."Name 4"::Initials:
                NamePart[4] := Initials;
            SalutationFormula."Name 4"::"Company Name":
                NamePart[4] := "Company Name";
        end;

        case SalutationFormula."Name 5" of
            SalutationFormula."Name 5"::"Job Title":
                NamePart[5] := "Job Title";
            SalutationFormula."Name 5"::"First Name":
                NamePart[5] := "First Name";
            SalutationFormula."Name 5"::"Middle Name":
                NamePart[5] := "Middle Name";
            SalutationFormula."Name 5"::Surname:
                NamePart[5] := Surname;
            SalutationFormula."Name 5"::Initials:
                NamePart[5] := Initials;
            SalutationFormula."Name 5"::"Company Name":
                NamePart[5] := "Company Name";
        end;

        OnAfterGetSalutation(SalutationType, LanguageCode, NamePart, Rec, SalutationFormula);

        exit(GetSalutationString(SalutationFormula, NamePart));
    end;

    procedure InheritCompanyToPersonData(NewCompanyContact: Record Contact)
    var
        IsHandled: Boolean;
    begin
        OnBeforeInheritCompanyToPersonData(Rec, xRec, NewCompanyContact, IsHandled);
        if IsHandled then
            exit;
        "Company Name" := NewCompanyContact.Name;

        RMSetup.Get();
        if RMSetup."Inherit Salesperson Code" then
            "Salesperson Code" := NewCompanyContact."Salesperson Code";
        if RMSetup."Inherit Territory Code" then
            "Territory Code" := NewCompanyContact."Territory Code";
        if RMSetup."Inherit Country/Region Code" then
            "Country/Region Code" := NewCompanyContact."Country/Region Code";
        if RMSetup."Inherit Language Code" then
            "Language Code" := NewCompanyContact."Language Code";
        if RMSetup."Inherit Address Details" and StaleAddress then begin
            Address := NewCompanyContact.Address;
            "Address 2" := NewCompanyContact."Address 2";
            "Post Code" := NewCompanyContact."Post Code";
            City := NewCompanyContact.City;
            County := NewCompanyContact.County;
        end;
        if RMSetup."Inherit Communication Details" then begin
            UpdateFieldForNewCompany(FieldNo("Phone No."));
            UpdateFieldForNewCompany(FieldNo("Telex No."));
            UpdateFieldForNewCompany(FieldNo("Fax No."));
            UpdateFieldForNewCompany(FieldNo("Telex Answer Back"));
            UpdateFieldForNewCompany(FieldNo("E-Mail"));
            UpdateFieldForNewCompany(FieldNo("Home Page"));
            UpdateFieldForNewCompany(FieldNo("Extension No."));
            UpdateFieldForNewCompany(FieldNo("Mobile Phone No."));
            UpdateFieldForNewCompany(FieldNo(Pager));
            UpdateFieldForNewCompany(FieldNo("Correspondence Type"));
        end;
        CalcFields("No. of Industry Groups", "No. of Business Relations");

        OnAfterInheritCompanyToPersonData(Rec, xRec, NewCompanyContact);
    end;

    local procedure StaleAddress() Stale: Boolean
    var
        OldCompanyContact: Record Contact;
        DummyContact: Record Contact;
    begin
        if OldCompanyContact.Get(xRec."Company No.") then
            Stale := IdenticalAddress(OldCompanyContact);
        Stale := Stale or IdenticalAddress(DummyContact);
    end;

    local procedure UpdateFieldForNewCompany(FieldNo: Integer)
    var
        OldCompanyContact: Record Contact;
        NewCompanyContact: Record Contact;
        OldCompanyRecRef: RecordRef;
        NewCompanyRecRef: RecordRef;
        ContactRecRef: RecordRef;
        ContactFieldRef: FieldRef;
        OldCompanyFieldValue: Text;
        ContactFieldValue: Text;
        Stale: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateFieldForNewCompany(Rec, FieldNo, IsHandled);
        if IsHandled then
            exit;

        ContactRecRef.GetTable(Rec);
        ContactFieldRef := ContactRecRef.Field(FieldNo);
        ContactFieldValue := Format(ContactFieldRef.Value);

        if NewCompanyContact.Get("Company No.") then begin
            NewCompanyRecRef.GetTable(NewCompanyContact);
            if OldCompanyContact.Get(xRec."Company No.") then begin
                OldCompanyRecRef.GetTable(OldCompanyContact);
                OldCompanyFieldValue := Format(OldCompanyRecRef.Field(FieldNo).Value);
                Stale := ContactFieldValue = OldCompanyFieldValue;
            end;
            if Stale or (ContactFieldValue = '') then begin
                ContactFieldRef.Validate(NewCompanyRecRef.Field(FieldNo).Value);
                ContactRecRef.SetTable(Rec);
            end;
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetHideValidationDialog(): Boolean
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        exit(HideValidationDialog or EnvInfoProxy.IsInvoicing);
    end;

    procedure DisplayMap()
    var
        MapPoint: Record "Online Map Setup";
        MapMgt: Codeunit "Online Map Management";
    begin
        if MapPoint.FindFirst then
            MapMgt.MakeSelection(DATABASE::Contact, GetPosition)
        else
            Message(Text033);
    end;

    local procedure ProcessNameChange()
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        UpdateSearchName;

        if Type = Type::Company then
            "Company Name" := Name;

        if Type = Type::Person then begin
            ContBusRel.Reset();
            ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
            ContBusRel.SetRange("Contact No.", "Company No.");
            if ContBusRel.FindFirst then
                if Cust.Get(ContBusRel."No.") then
                    if Cust."Primary Contact No." = "No." then begin
                        Cust.Contact := Name;
                        Cust.Modify();
                    end;

            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
            if ContBusRel.FindFirst then
                if Vend.Get(ContBusRel."No.") then
                    if Vend."Primary Contact No." = "No." then begin
                        Vend.Contact := Name;
                        Vend.Modify();
                    end;
        end;
        OnAfterProcessNameChange(Rec, Cust, Vend);
    end;

    procedure GetCompNo(ContactText: Text): Text
    var
        Contact: Record Contact;
        ContactWithoutQuote: Text;
        ContactFilterFromStart: Text;
        ContactFilterContains: Text;
        ContactNo: Code[20];
    begin
        if ContactText = '' then
            exit('');

        if StrLen(ContactText) <= MaxStrLen(Contact."Company No.") then
            if Contact.Get(CopyStr(ContactText, 1, MaxStrLen(Contact."Company No."))) then
                exit(Contact."No.");

        ContactWithoutQuote := ConvertStr(ContactText, '''', '?');

        Contact.SetRange(Type, Contact.Type::Company);

        Contact.SetFilter(Name, '''@' + ContactWithoutQuote + '''');
        if Contact.FindFirst then
            exit(Contact."No.");
        Contact.SetRange(Name);
        ContactFilterFromStart := '''@' + ContactWithoutQuote + '*''';
        Contact.FilterGroup := -1;
        Contact.SetFilter("No.", ContactFilterFromStart);
        Contact.SetFilter(Name, ContactFilterFromStart);
        if Contact.FindFirst then
            exit(Contact."No.");
        ContactFilterContains := '''@*' + ContactWithoutQuote + '*''';
        Contact.SetFilter("No.", ContactFilterContains);
        Contact.SetFilter(Name, ContactFilterContains);
        Contact.SetFilter(City, ContactFilterContains);
        Contact.SetFilter("Phone No.", ContactFilterContains);
        Contact.SetFilter("Post Code", ContactFilterContains);
        case Contact.Count of
            1:
                begin
                    Contact.FindFirst;
                    exit(Contact."No.");
                end;
            else begin
                    if not GuiAllowed then
                        Error(SelectContactErr);
                    ContactNo := SelectContact(Contact);
                    if ContactNo <> '' then
                        exit(ContactNo);
                end;
        end;
        Error(SelectContactErr);
    end;

    local procedure SelectContact(var Contact: Record Contact): Code[20]
    var
        ContactList: Page "Contact List";
    begin
        if Contact.FindSet then
            repeat
                Contact.Mark(true);
            until Contact.Next = 0;
        if Contact.FindFirst then;
        Contact.MarkedOnly := true;

        ContactList.SetTableView(Contact);
        ContactList.SetRecord(Contact);
        ContactList.LookupMode := true;
        if ContactList.RunModal = ACTION::LookupOK then
            ContactList.GetRecord(Contact)
        else
            Clear(Contact);

        exit(Contact."No.");
    end;

    procedure LookupCompany()
    var
        Contact: Record Contact;
        CompanyDetails: Page "Company Details";
    begin
        if "Company No." = '' then
            exit;

        Contact.Get("Company No.");
        CompanyDetails.SetRecord(Contact);
        CompanyDetails.Editable := false;
        CompanyDetails.RunModal;
    end;

    procedure LookupCustomerTemplate(): Code[20]
    var
        CustomerTemplate: Record "Customer Template";
        CustomerTemplateList: Page "Customer Template List";
    begin
        CustomerTemplate.FilterGroup(2);
        CustomerTemplate.SetRange("Contact Type", Type);
        CustomerTemplate.FilterGroup(0);
        CustomerTemplateList.LookupMode := true;
        OnLookupCustomerTemplateOnBeforeSetTableView(Rec, CustomerTemplate);
        CustomerTemplateList.SetTableView(CustomerTemplate);
        if CustomerTemplateList.RunModal = ACTION::LookupOK then begin
            CustomerTemplateList.GetRecord(CustomerTemplate);
            exit(CustomerTemplate.Code);
        end;
    end;

    procedure CheckForExistingRelationships(LinkToTable: Option " ",Customer,Vendor,"Bank Account")
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckForExistingRelationships(Rec, LinkToTable, IsHandled);
        if IsHandled then
            exit;

        Contact := Rec;
        ContBusRel."Link to Table" := LinkToTable;

        if "No." <> '' then begin
            if ContBusRel.FindByContact(LinkToTable, Contact."No.") then
                Error(
                  AlreadyExistErr,
                  Contact.TableCaption, "No.", ContBusRel.TableCaption, ContBusRel."Link to Table", ContBusRel."No.");
        end;
    end;

    procedure SetLastDateTimeModified()
    var
        UtcNow: DateTime;
        UserTimeZoneOffset: Duration;
    begin
        UtcNow := CurrentDateTime();
        UserTimeZoneOffset := GetTimeZoneOffset();
        UtcNow := UtcNow - UserTimeZoneOffset;
        "Last Date Modified" := DT2Date(UtcNow);
        "Last Time Modified" := DT2Time(UtcNow);

        OnAfterSetLastDateTimeModified(Rec);
    end;

    procedure GetLastDateTimeModified(): DateTime
    var
        Result: DateTime;
        UserTimeZoneOffset: Duration;
    begin
        if "Last Date Modified" = 0D then
            exit(0DT);

        Result := CreateDateTime("Last Date Modified", "Last Time Modified");
        UserTimeZoneOffset := GetTimeZoneOffset();
        exit(Result + UserTimeZoneOffset);
    end;

    local procedure GetTimeZoneOffset() UserTimeZoneOffset: Duration
    var
        TypeHelper: Codeunit "Type Helper";
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
    begin
        if not TypeHelper.GetUserTimezoneOffset(UserTimeZoneOffset) then
            UserTimeZoneOffset := DotNet_DateTimeOffset.GetOffset();
    end;

    procedure SetLastDateTimeFilter(DateFilter: DateTime)
    var
        SyncDateTimeUtc: DateTime;
        CurrentFilterGroup: Integer;
    begin
        SyncDateTimeUtc := DateFilter;
        SyncDateTimeUtc := SyncDateTimeUtc - GetTimeZoneOffset();
        CurrentFilterGroup := FilterGroup;
        SetFilter("Last Date Modified", '>=%1', DT2Date(SyncDateTimeUtc));
        FilterGroup(-1);
        SetFilter("Last Date Modified", '>%1', DT2Date(SyncDateTimeUtc));
        SetFilter("Last Time Modified", '>%1', DT2Time(SyncDateTimeUtc));
        FilterGroup(CurrentFilterGroup);
    end;

    procedure TouchContact(ContactNo: Code[20])
    var
        Cont: Record Contact;
    begin
        Cont.LockTable();
        if Cont.Get(ContactNo) then begin
            Cont.SetLastDateTimeModified;
            Cont.Modify();
        end;
    end;

    procedure CountNoOfBusinessRelations(): Integer
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if "Company No." <> '' then
            ContactBusinessRelation.SetFilter("Contact No.", '%1|%2', "No.", "Company No.")
        else
            ContactBusinessRelation.SetRange("Contact No.", "No.");
        exit(ContactBusinessRelation.Count);
    end;

    procedure CreateSalesQuoteFromContact()
    var
        SalesHeader: Record "Sales Header";
    begin
        OnBeforeCreateSalesQuoteFromContact(Rec, SalesHeader);

        CheckIfPrivacyBlockedGeneric;
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Document Date", WorkDate);
        SalesHeader.Validate("Sell-to Contact No.", "No.");
        SalesHeader.Modify();
        PAGE.Run(PAGE::"Sales Quote", SalesHeader);
    end;

    procedure ContactToCustBusinessRelationExist(): Boolean
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.Reset();
        ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        exit(ContBusRel.FindFirst);
    end;

    procedure CheckIfMinorForProfiles()
    begin
        if Minor then
            Error(ProfileForMinorErr);
    end;

    procedure CheckIfPrivacyBlocked(IsPosting: Boolean)
    begin
        if "Privacy Blocked" then begin
            if IsPosting then
                Error(PrivacyBlockedPostErr, "No.");
            Error(PrivacyBlockedCreateErr, "No.");
        end;
    end;

    procedure CheckIfPrivacyBlockedGeneric()
    begin
        if "Privacy Blocked" then
            Error(PrivacyBlockedGenericErr, "No.", Name);
    end;

    local procedure ValidateSalesPerson()
    begin
        if "Salesperson Code" <> '' then
            if Salesperson.Get("Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    Error(Salesperson.GetPrivacyBlockedGenericText(Salesperson, true))
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalutation(var SalutationType: Option Formal,Informal; var LanguageCode: Code[10]; var NamePart: array[5] of Text[100]; var Contact: Record Contact; var SalutationFormula: Record "Salutation Formula")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInheritCompanyToPersonData(var Contact: Record Contact; xContact: Record Contact; NewCompanyContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateQuotesForContact(Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendorInsert(var Vendor: Record Vendor; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeVendorInsert(var Vend: Record Vendor; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChooseCustomerTemplate(var Contact: Record Contact; var CustTemplateCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCustomerInsert(var Cust: Record Customer; CustomerTemplate: Code[10]; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindCustomerTemplate(var Contact: Record Contact; var CustTemplateCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsUpdateNeeded(Contact: Record Contact; xContact: Record Contact; var UpdateNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerOnBeforeCustomerModify(var Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerOnTransferFieldsFromTemplate(var Customer: Record Customer; CustomerTemplate: Record "Customer Template")
    begin
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) and (UserSetup."Salespers./Purch. Code" <> '') then
            "Salesperson Code" := UserSetup."Salespers./Purch. Code";
    end;

    local procedure VATRegistrationValidation()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ResultRecordRef: RecordRef;
        ApplicableCountryCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVATRegistrationValidation(Rec, IsHandled);
        if IsHandled then
            exit;

        if not VATRegistrationNoFormat.Test("VAT Registration No.", "Country/Region Code", "No.", DATABASE::Contact) then
            exit;

        VATRegistrationLogMgt.LogContact(Rec);

        if ("Country/Region Code" = '') and (VATRegistrationNoFormat."Country/Region Code" = '') then
            exit;
        ApplicableCountryCode := "Country/Region Code";
        if ApplicableCountryCode = '' then
            ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";

        if VATRegNoSrvConfig.VATRegNoSrvIsEnabled then begin
            VATRegistrationLogMgt.ValidateVATRegNoWithVIES(ResultRecordRef, Rec, "No.",
              VATRegistrationLog."Account Type"::Contact, ApplicableCountryCode);
            ResultRecordRef.SetTable(Rec);
        end;
    end;

    procedure GetContNo(ContactText: Text): Code[20]
    var
        Contact: Record Contact;
        ContactWithoutQuote: Text;
        ContactFilterFromStart: Text;
        ContactFilterContains: Text;
    begin
        if ContactText = '' then
            exit('');

        if StrLen(ContactText) <= MaxStrLen(Contact."No.") then
            if Contact.Get(CopyStr(ContactText, 1, MaxStrLen(Contact."No."))) then
                exit(Contact."No.");

        Contact.SetRange(Name, ContactText);
        if Contact.FindFirst then
            exit(Contact."No.");

        Contact.SetCurrentKey(Name);

        ContactWithoutQuote := ConvertStr(ContactText, '''', '?');
        Contact.SetFilter(Name, '''@' + ContactWithoutQuote + '''');
        if Contact.FindFirst then
            exit(Contact."No.");

        Contact.SetRange(Name);

        ContactFilterFromStart := '''@' + ContactWithoutQuote + '*''';
        Contact.FilterGroup := -1;
        Contact.SetFilter("No.", ContactFilterFromStart);
        Contact.SetFilter(Name, ContactFilterFromStart);
        if Contact.FindFirst then
            exit(Contact."No.");

        ContactFilterContains := '''@*' + ContactWithoutQuote + '*''';
        Contact.SetFilter("No.", ContactFilterContains);
        Contact.SetFilter(Name, ContactFilterContains);
        Contact.SetFilter(City, ContactFilterContains);
        Contact.SetFilter("Phone No.", ContactFilterContains);
        Contact.SetFilter("Post Code", ContactFilterContains);
        if Contact.Count = 0 then
            MarkContactsWithSimilarName(Contact, ContactText);

        if Contact.Count = 1 then begin
            Contact.FindFirst;
            exit(Contact."No.");
        end;

        exit('');
    end;

    local procedure MarkContactsWithSimilarName(var Contact: Record Contact; ContactText: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        ContactCount: Integer;
        ContactTextLength: Integer;
        Treshold: Integer;
    begin
        if ContactText = '' then
            exit;
        if StrLen(ContactText) > MaxStrLen(Contact.Name) then
            exit;

        ContactTextLength := StrLen(ContactText);
        Treshold := ContactTextLength div 5;
        if Treshold = 0 then
            exit;

        Contact.Reset();
        Contact.Ascending(false); // most likely to search for newest contacts
        if Contact.FindSet then
            repeat
                ContactCount += 1;
                if Abs(ContactTextLength - StrLen(Contact.Name)) <= Treshold then
                    if TypeHelper.TextDistance(UpperCase(ContactText), UpperCase(Contact.Name)) <= Treshold then
                        Contact.Mark(true);
            until Contact.Mark or (Contact.Next = 0) or (ContactCount > 1000);
        Contact.MarkedOnly(true);
    end;

    local procedure IsUpdateNeeded(): Boolean
    var
        UpdateNeeded: Boolean;
    begin
        UpdateNeeded :=
          (Name <> xRec.Name) or
          ("Search Name" <> xRec."Search Name") or
          ("Name 2" <> xRec."Name 2") or
          (Address <> xRec.Address) or
          ("Address 2" <> xRec."Address 2") or
          (City <> xRec.City) or
          ("Phone No." <> xRec."Phone No.") or
          ("Telex No." <> xRec."Telex No.") or
          ("Territory Code" <> xRec."Territory Code") or
          ("Currency Code" <> xRec."Currency Code") or
          ("Language Code" <> xRec."Language Code") or
          ("Salesperson Code" <> xRec."Salesperson Code") or
          ("Country/Region Code" <> xRec."Country/Region Code") or
          ("Fax No." <> xRec."Fax No.") or
          ("Telex Answer Back" <> xRec."Telex Answer Back") or
          ("VAT Registration No." <> xRec."VAT Registration No.") or
          ("Post Code" <> xRec."Post Code") or
          (County <> xRec.County) or
          ("E-Mail" <> xRec."E-Mail") or
          ("Home Page" <> xRec."Home Page") or
          (Type <> xRec.Type);

        OnBeforeIsUpdateNeeded(Rec, xRec, UpdateNeeded);
        exit(UpdateNeeded);
    end;

    local procedure GetSalutationString(SalutationFormula: Record "Salutation Formula"; NamePart: array[5] of Text[100]) SalutationString: Text[260]
    var
        SubStr: Text;
        i: Integer;
    begin
        for i := 1 to 5 do
            if NamePart[i] = '' then begin
                SubStr := '%' + Format(i) + ' ';
                if StrPos(SalutationFormula.Salutation, SubStr) > 0 then
                    SalutationFormula.Salutation :=
                      DelStr(SalutationFormula.Salutation, StrPos(SalutationFormula.Salutation, SubStr), 3);
            end;
        SalutationString := CopyStr(StrSubstNo(SalutationFormula.Salutation, NamePart[1], NamePart[2], NamePart[3], NamePart[4], NamePart[5]), 1, MaxStrLen(SalutationString));

        OnGetSalutationString(SalutationString, SalutationFormula, NamePart);
    end;

    procedure GetContactsSelectionFromContactList(SelectMode: Boolean): Boolean
    var
        ContactList: Page "Contact List";
    begin
        ContactList.LookupMode(SelectMode);
        ContactList.SetTableView(Rec);
        if ContactList.RunModal() = Action::LookupOK then begin
            SetFilter("No.", ContactList.GetSelectionFilter());
            exit(FindSet());
        end;
        exit(false);
    end;

    local procedure SetSearchEmail()
    begin
        if "Search E-Mail" <> "E-Mail".ToUpper() then
            "Search E-Mail" := "E-Mail";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLink(var Contact: Record Contact; var TempContBusRel: Record "Contact Business Relation"; var CreateForm: Integer; var BusRelCode: Code[10]; var Table: Enum "Contact Business Relation Link To Table")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInheritCompanyToPersonData(var Contact: Record Contact; xContact: Record Contact; var NewCompanyContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatedName(var Contact: Record Contact; var NewName92: Text[92])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomer(var Contact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateVendor(var Contact: Record Contact; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIdenticalAddress(Contact: Record Contact; RecContact: Record Contact; var IsIdentical: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifySellToCustomerNo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyBillToCustomerNo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnModify(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessNameChange(var Contact: Record Contact; Customer: Record Customer; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaults(var Contact: Record Contact; MarketingSetup: Record "Marketing Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLastDateTimeModified(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTypeForContact(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowCustVendBank(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; FormSelected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSyncAddress(var Contact: Record Contact; RecContact: Record Contact; var ContChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCity(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyCompanyChangeToPerson(var PersonContact: Record Contact; Contact: Record Contact; xContact: Record Contact; var ContChanged: Boolean; OldContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Contact: record Contact; OldContact: Record Contact; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankAccountInsert(var BankAccount: Record "Bank Account");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDuplicateCheck(Contact: Record Contact; xContact: Record Contact; var IsDuplicateCheckNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatedName(var Contact: Record Contact; var NewName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckForExistingRelationships(var Contact: Record Contact; LinkToTable: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCompanyNo(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDuplicates(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesQuoteFromContact(var Contact: Record Contact; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVendor(var Contact: Record Contact; var VendorNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalutation(var Contact: Record Contact; var SalutationType: Option Formal,Informal; var LanguageCode: Code[10]; var IsHandled: Boolean; var Salutation: Text[260])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupCity(var Contact: Record Contact; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostCode(var Contact: Record Contact; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNameBreakdown(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATRegistrationValidation(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var Contact: Record Contact; var PostCode: Record "Post Code");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchDuplicateForm(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCompanyNo(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFieldForNewCompany(var Contact: Record Contact; var FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSearchName(var Contact: Record Contact; xContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var Contact: Record Contact; var PostCode: Record "Post Code");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerOnBeforeUpdateQuotes(var Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorOnAfterUpdateVendor(var Vendor: Record Vendor; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupCustomerTemplateOnBeforeSetTableView(Contact: Record Contact; var CustomerTemplate: Record "Customer Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalutationString(var SalutationString: Text[260]; SalutationFormula: Record "Salutation Formula"; NamePart: array[5] of Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCustVendBankCaseElse(var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCustVendBankOnBeforeRunPage(var Contact: Record Contact; FormSelected: Boolean; var ContBusRel: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnTypeChangeOnAfterCheckInteractionLog(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;
}

