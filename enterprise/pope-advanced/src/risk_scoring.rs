use crate::attestation_check::AttestationVerifier;
use crate::anti_spoofing_gps::GPSSpoofDetector;

pub enum RiskTier { Maximum, High, Medium, Blocked }

pub struct RiskEngine;

impl RiskEngine {
    /// Consolida todas las señales de hardware en un Score de Veracidad.
    /// PROPIETARIO: Este score es lo que el banco compra.
    pub fn calculate_veracity_score(hw_valid: bool, gps_valid: bool) -> RiskTier {
        if hw_valid && gps_valid {
            RiskTier::Maximum
        } else if hw_valid {
            RiskTier::High
        } else {
            RiskTier::Medium
        }
    }
}
