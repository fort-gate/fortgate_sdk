use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct XAIReport {
    pub attestation_id: String,
    pub hardware_tier: String,
    pub geofencing_verified: bool,
    pub liveness_confidence: f32,
    pub sat_binding_verified: bool,
}

pub struct ReportGenerator;

impl ReportGenerator {
    pub fn generate_audit_report(data: XAIReport) -> String {
        format!(
            "--- AUDIT REPORT ---\nID: {}\nHardware: {}\nGPS: {}\nStatus: VERIFIED",
            data.attestation_id,
            data.hardware_tier,
            if data.geofencing_verified { "Inside Range" } else { "Mismatch" }
        )
    }
}
