const { create_fortgate_witness_wasm } = require('../pkg/fortgate_id');
const fs = require('fs');
const path = require('path');

async function test() {
    console.log("🛡️ Fortgate ID Smoke Test (W2-P3.3)");
    
    // W2-P3.3: Ruta alineada al nuevo layout
    const fixturePath = path.join(__dirname, 'fixtures/mock.der');
    
    if (!fs.existsSync(fixturePath)) {
        console.error("❌ Fixture not found at:", fixturePath);
        process.exit(1);
    }

    const cert = fs.readFileSync(fixturePath);
    try {
        const witness = create_fortgate_witness_wasm(new Uint8Array(cert));
        console.log("✅ Nullifier generated:", witness.nullifier_hash);
        console.log("✅ Test Passed: WASM integration is stable.");
    } catch (e) {
        console.error("❌ Test Failed:", e);
        process.exit(1);
    }
}

test().catch(console.error);
