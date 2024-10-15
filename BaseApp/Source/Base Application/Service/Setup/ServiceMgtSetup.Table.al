﻿namespace Microsoft.Service.Setup;

using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.NoSeries;
using Microsoft.Service.Contract;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;
#if not CLEAN23
using System.Environment.Configuration;
using System.Telemetry;
#endif

table 5911 "Service Mgt. Setup"
{
    Caption = 'Service Mgt. Setup';
    DrillDownPageID = "Service Mgt. Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(4; "Fault Reporting Level"; Option)
        {
            Caption = 'Fault Reporting Level';
            InitValue = Fault;
            OptionCaption = 'None,Fault,Fault+Symptom,Fault+Symptom+Area (IRIS)';
            OptionMembers = "None",Fault,"Fault+Symptom","Fault+Symptom+Area (IRIS)";
        }
        field(5; "Link Service to Service Item"; Boolean)
        {
            Caption = 'Link Service to Service Item';
        }
        field(7; "Salesperson Mandatory"; Boolean)
        {
            AccessByPermission = TableData "Salesperson/Purchaser" = R;
            Caption = 'Salesperson Mandatory';
        }
        field(8; "Warranty Disc. % (Parts)"; Decimal)
        {
            Caption = 'Warranty Disc. % (Parts)';
            DecimalPlaces = 1 : 1;
            InitValue = 100;
            MaxValue = 100;
            MinValue = 0;
        }
        field(9; "Warranty Disc. % (Labor)"; Decimal)
        {
            Caption = 'Warranty Disc. % (Labor)';
            DecimalPlaces = 1 : 1;
            InitValue = 100;
            MaxValue = 100;
            MinValue = 0;
        }
        field(11; "Contract Rsp. Time Mandatory"; Boolean)
        {
            Caption = 'Contract Rsp. Time Mandatory';
        }
        field(13; "Service Order Starting Fee"; Code[10])
        {
            Caption = 'Service Order Starting Fee';
            TableRelation = "Service Cost";
        }
        field(14; "Register Contract Changes"; Boolean)
        {
            Caption = 'Register Contract Changes';
        }
        field(15; "Contract Inv. Line Text Code"; Code[20])
        {
            Caption = 'Contract Inv. Line Text Code';
            TableRelation = "Standard Text";
        }
        field(16; "Contract Line Inv. Text Code"; Code[20])
        {
            Caption = 'Contract Line Inv. Text Code';
            TableRelation = "Standard Text";
        }
        field(19; "Contract Inv. Period Text Code"; Code[20])
        {
            Caption = 'Contract Inv. Period Text Code';
            TableRelation = "Standard Text";
        }
        field(20; "Contract Credit Line Text Code"; Code[20])
        {
            Caption = 'Contract Credit Line Text Code';
            TableRelation = "Standard Text";
        }
        field(23; "Send First Warning To"; Text[80])
        {
            Caption = 'Send First Warning To';
        }
        field(24; "Send Second Warning To"; Text[80])
        {
            Caption = 'Send Second Warning To';
        }
        field(25; "Send Third Warning To"; Text[80])
        {
            Caption = 'Send Third Warning To';
        }
        field(26; "First Warning Within (Hours)"; Decimal)
        {
            Caption = 'First Warning Within (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(27; "Second Warning Within (Hours)"; Decimal)
        {
            Caption = 'Second Warning Within (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(28; "Third Warning Within (Hours)"; Decimal)
        {
            Caption = 'Third Warning Within (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(29; "Next Service Calc. Method"; Option)
        {
            Caption = 'Next Service Calc. Method';
            OptionCaption = 'Planned,Actual';
            OptionMembers = Planned,Actual;
        }
        field(30; "Service Order Type Mandatory"; Boolean)
        {
            Caption = 'Service Order Type Mandatory';
        }
        field(31; "Service Zones Option"; Option)
        {
            Caption = 'Service Zones Option';
            OptionCaption = 'Code Shown,Warning Displayed,Not Used';
            OptionMembers = "Code Shown","Warning Displayed","Not Used";
        }
        field(32; "Service Order Start Mandatory"; Boolean)
        {
            Caption = 'Service Order Start Mandatory';
        }
        field(33; "Service Order Finish Mandatory"; Boolean)
        {
            Caption = 'Service Order Finish Mandatory';
        }
        field(36; "Resource Skills Option"; Option)
        {
            Caption = 'Resource Skills Option';
            OptionCaption = 'Code Shown,Warning Displayed,Not Used';
            OptionMembers = "Code Shown","Warning Displayed","Not Used";
        }
        field(37; "One Service Item Line/Order"; Boolean)
        {
            Caption = 'One Service Item Line/Order';
        }
        field(38; "Unit of Measure Mandatory"; Boolean)
        {
            Caption = 'Unit of Measure Mandatory';
        }
        field(39; "Fault Reason Code Mandatory"; Boolean)
        {
            Caption = 'Fault Reason Code Mandatory';
        }
        field(40; "Contract Serv. Ord.  Max. Days"; Integer)
        {
            Caption = 'Contract Serv. Ord.  Max. Days';
            MinValue = 0;
        }
        field(41; "Last Contract Service Date"; Date)
        {
            Caption = 'Last Contract Service Date';
            Editable = false;
        }
        field(42; "Work Type Code Mandatory"; Boolean)
        {
            Caption = 'Work Type Code Mandatory';
        }
        field(43; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(44; "Use Contract Cancel Reason"; Boolean)
        {
            Caption = 'Use Contract Cancel Reason';
        }
        field(45; "Default Response Time (Hours)"; Decimal)
        {
            Caption = 'Default Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(52; "Default Warranty Duration"; DateFormula)
        {
            Caption = 'Default Warranty Duration';
        }
        field(54; "Service Invoice Nos."; Code[20])
        {
            Caption = 'Service Invoice Nos.';
            TableRelation = "No. Series";
        }
        field(55; "Contract Invoice Nos."; Code[20])
        {
            Caption = 'Contract Invoice Nos.';
            TableRelation = "No. Series";
        }
        field(56; "Service Item Nos."; Code[20])
        {
            Caption = 'Service Item Nos.';
            TableRelation = "No. Series";
        }
        field(57; "Service Order Nos."; Code[20])
        {
            Caption = 'Service Order Nos.';
            TableRelation = "No. Series";
        }
        field(58; "Service Contract Nos."; Code[20])
        {
            AccessByPermission = TableData "Service Contract Line" = R;
            Caption = 'Service Contract Nos.';
            TableRelation = "No. Series";
        }
        field(59; "Contract Template Nos."; Code[20])
        {
            AccessByPermission = TableData "Service Contract Line" = R;
            Caption = 'Contract Template Nos.';
            TableRelation = "No. Series";
        }
        field(60; "Troubleshooting Nos."; Code[20])
        {
            Caption = 'Troubleshooting Nos.';
            TableRelation = "No. Series";
        }
        field(61; "Prepaid Posting Document Nos."; Code[20])
        {
            Caption = 'Prepaid Posting Document Nos.';
            TableRelation = "No. Series";
        }
        field(62; "Loaner Nos."; Code[20])
        {
            Caption = 'Loaner Nos.';
            TableRelation = "No. Series";
        }
        field(63; "Serv. Job Responsibility Code"; Code[10])
        {
            Caption = 'Serv. Job Responsibility Code';
            TableRelation = "Job Responsibility".Code;
        }
        field(64; "Contract Value Calc. Method"; Option)
        {
            Caption = 'Contract Value Calc. Method';
            OptionCaption = 'None,Based on Unit Price,Based on Unit Cost';
            OptionMembers = "None","Based on Unit Price","Based on Unit Cost";
        }
        field(65; "Contract Value %"; Decimal)
        {
            Caption = 'Contract Value %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(66; "Service Quote Nos."; Code[20])
        {
            Caption = 'Service Quote Nos.';
            TableRelation = "No. Series";
        }
        field(68; "Posted Service Invoice Nos."; Code[20])
        {
            Caption = 'Posted Service Invoice Nos.';
            TableRelation = "No. Series";
        }
        field(69; "Posted Serv. Credit Memo Nos."; Code[20])
        {
            Caption = 'Posted Serv. Credit Memo Nos.';
            TableRelation = "No. Series";
        }
        field(70; "Posted Service Shipment Nos."; Code[20])
        {
            Caption = 'Posted Service Shipment Nos.';
            TableRelation = "No. Series";
        }
        field(76; "Shipment on Invoice"; Boolean)
        {
            Caption = 'Shipment on Invoice';
        }
        field(77; "Skip Manual Reservation"; Boolean)
        {
            Caption = 'Skip Manual Reservation';
            DataClassification = SystemMetadata;
        }
        field(81; "Copy Comments Order to Invoice"; Boolean)
        {
            Caption = 'Copy Comments Order to Invoice';
            InitValue = true;
        }
        field(82; "Copy Comments Order to Shpt."; Boolean)
        {
            Caption = 'Copy Comments Order to Shpt.';
            InitValue = true;
        }
        field(85; "Service Credit Memo Nos."; Code[20])
        {
            Caption = 'Service Credit Memo Nos.';
            TableRelation = "No. Series";
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            DataClassification = SystemMetadata;

            trigger OnValidate()
#if not CLEAN23
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
                FeatureKeyManagement: Codeunit "Feature Key Management";
#endif
            begin
#if not CLEAN23
                if "Allow Multiple Posting Groups" then
                    FeatureTelemetry.LogUptake(
                        '0000JRB', FeatureKeyManagement.GetAllowMultipleCustVendPostingGroupsFeatureKey(), Enum::"Feature Uptake Status"::Discovered);
#endif
            end;
        }
        field(176; "Check Multiple Posting Groups"; enum "Posting Group Change Method")
        {
            Caption = 'Check Multiple Posting Groups';
            DataClassification = SystemMetadata;
        }
        field(200; "Serv. Inv. Template Name"; Code[10])
        {
            Caption = 'Serv. Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(201; "Serv. Contr. Inv. Templ. Name"; Code[10])
        {
            Caption = 'Serv. Contract Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(202; "Serv. Contr. Cr.M. Templ. Name"; Code[10])
        {
            Caption = 'Serv. Contract Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(203; "Serv. Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'Serv. Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(210; "Copy Line Descr. to G/L Entry"; Boolean)
        {
            Caption = 'Copy Line Descr. to G/L Entry';
            DataClassification = SystemMetadata;
        }
        field(810; "Invoice Posting Setup"; Enum "Service Invoice Posting")
        {
            Caption = 'Invoice Posting Setup';
            ObsoleteReason = 'Replaced by direct selection of posting interface in codeunits.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(950; "Copy Time Sheet to Order"; Boolean)
        {
            Caption = 'Copy Time Sheet to Order';
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(7601; "Contract Credit Memo Nos."; Code[20])
        {
            AccessByPermission = TableData "Service Contract Line" = R;
            Caption = 'Contract Credit Memo Nos.';
            TableRelation = "No. Series";
        }
        field(11300; "Jnl. Templ. Serv. Inv."; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. Inv.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ObsoleteReason = 'Replaced by W1 field Serv. Inv. Template Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(11301; "Jnl. Templ. Serv. Contr. Inv."; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. Contr. Inv.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ObsoleteReason = 'Replaced by W1 field Serv. Contr. Inv. Templ. Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(11302; "Jnl. Templ. Serv. Contr. CM"; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. Contr. CM';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ObsoleteReason = 'Replaced by W1 field Serv. Contr. Cr.M. Templ. Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(11303; "Jnl. Templ. Serv. CM"; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. CM';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ObsoleteReason = 'Replaced by W1 field Serv. Cr. Memo Templ. Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecordHasBeenRead: Boolean;

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
    end;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;
}

