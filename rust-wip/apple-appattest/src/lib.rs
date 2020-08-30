use serde::{Serialize, Deserialize};
use std::collections::LinkedList;
use serde_bytes::ByteBuf;

#[derive(Debug, Serialize, Deserialize)]
struct VerifyPacketAttStmt {
    x5c: Vec<Vec<u8>>,

    #[serde(with = "serde_bytes")]
    receipt: Vec<u8>,
}

#[derive(Debug, Serialize, Deserialize)]
struct VerifyPacket {
    fmt: String,
    attStmt: VerifyPacketAttStmt,

    // #[serde(with = "serde_bytes")]
    authData: ByteBuf,
}


#[cfg(test)]
mod tests {
    use std::fs::{File};
    use std::path::{PathBuf, Path};
    use crate::VerifyPacket;

    const ATTESTATION_FILE: &str = "tests/resources/attestation.cbor";

    fn get_test_file_path() -> PathBuf {
        let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        d.push(ATTESTATION_FILE);
        return d;
    }

    // fn get_test_data() -> Vec<u8> {
    //     let attestation_data = fs::read(get_test_file_path())
    //         .expect("Could not read test file");
    //     return attestation_data;
    // }

    #[test]
    fn it_works() {
        let attestation_data = File::open(get_test_file_path())
            .expect("Could not find test data file.");
        let att: VerifyPacket = serde_cbor::from_reader(attestation_data)
            .expect("Could not read data");

        println!("{:?}", att);

        assert_eq!(2 + 2, 5);
    }
}
